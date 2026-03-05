import 'dart:developer';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

part 'get_topic_list_state.dart';

class TopicCubit extends Cubit<TopicState> {
  TopicCubit() : super(TopicInitial());

  // Memory cache for instant loading
  static final Map<int, List<Map<String, dynamic>>> _memoryCache = {};

  Future<void> fetchTopics(int topicId, {bool forceRefresh = false}) async {
    try {
      // Check memory cache first for INSTANT loading - NO state change before this
      if (!forceRefresh && _memoryCache.containsKey(topicId)) {
        emit(TopicLoaded(_memoryCache[topicId]!));
        debugPrint("✅ Topics loaded from memory cache");
        return;
      }

      // Check local cache next - still NO state change
      final localData = await TopicLocalHelper.getFromLocal(topicId);
      if (!forceRefresh && localData != null && localData.isNotEmpty) {
        _memoryCache[topicId] = localData;
        emit(TopicLoaded(localData));
        debugPrint("✅ Topics loaded from local cache");
        
        // Refresh in background if data is old (24+ hours)
        _refreshInBackground(topicId);
        return;
      }

      // Only show loading if NO cache exists
      emit(TopicLoading());

      final apiService = await ApiService.create();
      final topicsResponse = await apiService.fetchTopics(topicId);
      
      if (topicsResponse.status == "success") {
        final topics = topicsResponse.data.map((topic) {
          return {
            'title': topic.topicsName,
            'id': topic.id,
            'image': topic.topicsImage,
            'isCompleted': topic.isCompleted,
          };
        }).toList();

        debugPrint('Topics fetched: ${topics.length}');

        // Save to caches
        _memoryCache[topicId] = topics;
        await TopicLocalHelper.saveToLocal(topicId, topics);

        emit(TopicLoaded(topics));
      } else {
        emit(TopicError("Failed to load topics"));
      }
    } catch (e) {
      debugPrint("Error in fetchTopics: $e");
      emit(TopicError("Error fetching topics: $e"));
    }
  }

  Future<void> _refreshInBackground(int topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt("topics_last_update_$topicId") ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceUpdate = (now - lastUpdate) / (1000 * 60 * 60);

      if (hoursSinceUpdate > 24) {
        debugPrint("🔄 Refreshing topics in background");
        final apiService = await ApiService.create();
        final topicsResponse = await apiService.fetchTopics(topicId);

        if (topicsResponse.status == "success") {
          final topics = topicsResponse.data.map((topic) {
            return {
              'title': topic.topicsName,
              'id': topic.id,
              'image': topic.topicsImage,
              'isCompleted': topic.isCompleted,
            };
          }).toList();

          _memoryCache[topicId] = topics;
          await TopicLocalHelper.saveToLocal(topicId, topics);
          emit(TopicLoaded(topics));
        }
      }
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    }
  }

  // Clear all caches
  static Future<void> clearAllCache() async {
    _memoryCache.clear();
    await TopicLocalHelper.clearLocal();
  }
}

class TopicLocalHelper {
  static const _cacheKeyPrefix = 'topics_data_';
  static const _timestampPrefix = 'topics_last_update_';

  static String _getCacheKey(int topicId) => '$_cacheKeyPrefix$topicId';

  static Future<void> saveToLocal(int topicId, List<Map<String, dynamic>> topics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(topics);
      await prefs.setString(_getCacheKey(topicId), jsonString);
      await prefs.setInt('$_timestampPrefix$topicId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Error saving topics to local: $e");
    }
  }

  static Future<List<Map<String, dynamic>>?> getFromLocal(int topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getCacheKey(topicId));
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint("Error loading topics from local: $e");
      return null;
    }
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
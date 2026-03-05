import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import '../../models/dragand_learn_model.dart';
import '../../services/api_service.dart';
part 'drag_and_learn_state.dart';

class DragLearnCubit extends Cubit<DragLearnState> {
  DragLearnCubit() : super(DragLearnInitial());

  // Cache to prevent multiple downloads of same image
  static final Map<String, String> _imageCache = {};
  static final Map<int, DragAndLearnLevelModel> _memoryCache = {};
  static final Map<int, int> _levelCache = {};

  Future<void> fetchDragLearnData({
    required int bookId,
    bool? isLoading,
    int? levelFrom,
    bool forceRefresh = false,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      int savedLevel = pref.getInt("DragAndLearnQuestLevel") ?? 0;
      
      if (levelFrom != null && levelFrom > savedLevel) {
        pref.setInt("DragAndLearnQuestLevel", levelFrom);
        savedLevel = levelFrom;
        _levelCache[bookId] = savedLevel;
      } else if (_levelCache.containsKey(bookId)) {
        savedLevel = _levelCache[bookId]!;
      } else {
        _levelCache[bookId] = savedLevel;
      }

      // Check memory cache first for INSTANT loading - NO state change before this
      if (!forceRefresh && _memoryCache.containsKey(bookId)) {
        emit(DragLearnLoaded(_memoryCache[bookId]!, savedLevel));
        debugPrint("✅ Instant load from memory cache");
        return;
      }

      // Check local cache next - still NO loading state shown
      final localData = await DragLearnLocalHelper.getFromLocal(bookId);
      if (!forceRefresh && localData != null && localData.data?.isNotEmpty == true) {
        _memoryCache[bookId] = localData;
        emit(DragLearnLoaded(localData, savedLevel));
        debugPrint("✅ Fast load from local cache");
        
        // Check if we need to refresh in background (silently)
        final lastUpdate = pref.getInt("drag_learn_last_update_$bookId") ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final hoursSinceUpdate = (now - lastUpdate) / (1000 * 60 * 60);
        
        if (hoursSinceUpdate > 24) {
          _refreshInBackground(bookId, pref.getString("auth_token"), savedLevel, pref);
        }
        return;
      }

      // Only show loading if NO cache exists at all
      emit(DragLearnLoading());
      
      String? token = pref.getString("auth_token");
      await _fetchFromAPI(bookId, token, savedLevel, levelFrom, pref);
    } catch (e) {
      debugPrint("Error in fetchDragLearnData: $e");
      emit(DragLearnFailed("Error: $e"));
    }
  }

  Future<void> _refreshInBackground(
    int bookId,
    String? token,
    int savedLevel,
    SharedPreferences pref,
  ) async {
    try {
      debugPrint("🔄 Refreshing data in background (silent)");
      await _fetchFromAPI(bookId, token, savedLevel, null, pref, silent: true);
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    }
  }

  Future<void> _fetchFromAPI(
    int bookId,
    String? token,
    int savedLevel,
    int? levelFrom,
    SharedPreferences pref, {
    bool silent = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}dragandlearn.php'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"book_id": bookId}),
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        if (levelFrom != null && levelFrom > savedLevel) {
          pref.setInt("DragAndLearnQuestLevel", levelFrom);
          savedLevel = levelFrom;
          _levelCache[bookId] = savedLevel;
        }

        DragAndLearnLevelModel model = DragAndLearnLevelModel.fromJson(data);

        // Process images with intelligent caching
        await _processImagesWithCache(model);

        // Save to local storage
        await DragLearnLocalHelper.saveToLocal(model, bookId);
        await pref.setInt("drag_learn_last_update_$bookId", DateTime.now().millisecondsSinceEpoch);
        
        // Update memory cache
        _memoryCache[bookId] = model;
        
        debugPrint("✅ API fetch complete");

        // Always emit, even if silent (this updates the UI with fresh data)
        emit(DragLearnLoaded(model, savedLevel));
      } else {
        if (!silent) {
          emit(DragLearnFailed("API responded with failure ❌"));
        }
      }
    } catch (e) {
      if (!silent) {
        emit(DragLearnFailed("Error: $e"));
      }
      debugPrint("API fetch error: $e");
    }
  }

  Future<void> _processImagesWithCache(DragAndLearnLevelModel model) async {
    for (final Data topic in model.data ?? <Data>[]) {
      for (final Levels level in topic.levels ?? <Levels>[]) {
        for (final Questions q in level.questions ?? <Questions>[]) {
          final String? imageUrl = q.qusImage;

          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Skip if it's already a local path
            if (imageUrl.startsWith('/')) {
              if (_imageCache.containsKey(imageUrl) == false) {
                _imageCache[imageUrl] = imageUrl;
              }
              continue;
            }
            
            if (imageUrl.startsWith('http') ||
                imageUrl.startsWith('https') ||
                imageUrl.startsWith('www')) {
              
              // Check if already cached in memory
              if (_imageCache.containsKey(imageUrl)) {
                q.qusImage = _imageCache[imageUrl];
                continue;
              }

              // Check if already saved locally
              final localPath = await _getLocalImagePath(imageUrl);
              if (localPath != null && await File(localPath).exists()) {
                q.qusImage = localPath;
                _imageCache[imageUrl] = localPath;
                continue;
              }

              // Download and save new image
              final String fullUrl = imageUrl.contains('picturoenglish.com')
                  ? imageUrl
                  : 'https://cdn.jsdelivr.net/gh/Mercurysoftech/PicturoEnglish@main/images_app/$imageUrl';

              final String? downloadedPath = await downloadAndSaveImage(fullUrl, imageUrl);
              if (downloadedPath != null) {
                q.qusImage = downloadedPath;
                _imageCache[imageUrl] = downloadedPath;
              }
            }
          }
        }
      }
    }
  }

  Future<String?> _getLocalImagePath(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final hash = md5.convert(utf8.encode(url)).toString();
    final path = '${dir.path}/drag_learn_$hash.jpg';
    return path;
  }

  Future<String?> downloadAndSaveImage(String url, String originalUrl) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        debugPrint('Storage permission denied ❌');
        return null;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final hash = md5.convert(utf8.encode(originalUrl)).toString();
        final path = '${dir.path}/drag_learn_$hash.jpg';
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        return path;
      } else {
        debugPrint("Image download failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
    }
    return null;
  }

  // Update level completion status in cache
  Future<void> updateLevelCompletion({
    required int bookId,
    required int topicId,
    required int levelIndex,
    required bool completed,
  }) async {
    try {
      // Update memory cache
      if (_memoryCache.containsKey(bookId)) {
        final model = _memoryCache[bookId]!;
        final topic = model.data?.firstWhere(
          (t) => t.topicId == topicId,
          orElse: () => Data(),
        );
        
        if (topic?.levels != null && levelIndex < topic!.levels!.length) {
          topic.levels![levelIndex].completed = completed;
          
          // Save updated data to local storage
          await DragLearnLocalHelper.saveToLocal(model, bookId);
          
          // Emit updated state
          final savedLevel = _levelCache[bookId] ?? 0;
          emit(DragLearnLoaded(model, savedLevel));
          
          debugPrint("✅ Level completion updated in cache");
        }
      } else {
        // If not in memory cache, force refresh
        await fetchDragLearnData(bookId: bookId, forceRefresh: true);
      }
    } catch (e) {
      debugPrint("Error updating level completion: $e");
    }
  }

  // Clear all caches
  static Future<void> clearAllCache() async {
    _imageCache.clear();
    _memoryCache.clear();
    _levelCache.clear();
    await DragLearnLocalHelper.clearLocal();
  }
}

class DragLearnLocalHelper {
  static const _cacheKeyPrefix = 'drag_learn_data_';

  static String _getCacheKey(int bookId) => '$_cacheKeyPrefix$bookId';

  static Future<void> saveToLocal(DragAndLearnLevelModel model, int bookId) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode({
      'status': model.status,
      'data': model.data
          ?.map((topic) => {
                'topic_id': topic.topicId,
                'levels': topic.levels
                    ?.map((lvl) => {
                          'level': lvl.level,
                          'completed': lvl.completed,
                          'questions': lvl.questions
                              ?.map((q) => {
                                    'id': q.id,
                                    'question': q.question,
                                    'meaning': q.meaning,
                                    'example': q.example,
                                    'qus_image': q.qusImage,
                                  })
                              .toList(),
                        })
                    .toList(),
              })
          .toList(),
    });

    await prefs.setString(_getCacheKey(bookId), jsonString);
  }

  static Future<DragAndLearnLevelModel?> getFromLocal(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getCacheKey(bookId));
      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString);
      return DragAndLearnLevelModel.fromJson(jsonMap);
    } catch (e) {
      debugPrint("Error loading from local cache: $e");
      return null;
    }
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
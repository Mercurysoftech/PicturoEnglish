import 'dart:developer';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../responses/friends_response.dart';
import '../../../services/api_service.dart';

part 'get_friends_list_state.dart';

class GetFriendsListCubit extends Cubit<GetFriendsListState> {
  GetFriendsListCubit() : super(GetFriendsListInitial());

  // TIER 1: Memory Cache (Instant - 0ms)
  static List<Friends>? _memoryCache;
  static int? _lastFetchTimestamp;

  Future<void> fetchAllFriends({bool forceRefresh = false}) async {
    try {
      // TIER 1: Check Memory Cache (Instant!)
      if (!forceRefresh && _memoryCache != null) {
        emit(GetFriendsListLoaded(friends: _memoryCache!));
        debugPrint("⚡ Friends loaded from memory cache");
        
        // Check if data is stale (> 5 minutes for chat lists)
        if (_lastFetchTimestamp != null) {
          final minutesSinceUpdate = 
              (DateTime.now().millisecondsSinceEpoch - _lastFetchTimestamp!) / 
              (1000 * 60);
          
          if (minutesSinceUpdate > 5) {
            _refreshInBackground();
          }
        }
        return;
      }

      // TIER 2: Check Local Storage (Fast!)
      final localData = await _getFromLocal();
      if (!forceRefresh && localData != null && localData.isNotEmpty) {
        _memoryCache = localData;
        emit(GetFriendsListLoaded(friends: localData));
        debugPrint("💾 Friends loaded from local cache");
        
        // Refresh in background if older than 5 minutes
        _refreshInBackground();
        return;
      }

      // TIER 3: Fetch from Network (Only if no cache)
      if (state is GetFriendsListInitial) {
        emit(GetFriendsListLoading());
      }
      
      await _fetchFromAPI();
    } catch (e) {
      debugPrint("Error in fetchAllFriends: $e");
      emit(GetFriendsListFailed());
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt("friends_last_update") ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final minutesSinceUpdate = (now - lastUpdate) / (1000 * 60);

      if (minutesSinceUpdate > 5) {
        debugPrint("🔄 Refreshing friends in background");
        await _fetchFromAPI(silent: true);
      }
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    }
  }

  Future<void> _fetchFromAPI({bool silent = false}) async {
    try {
      final apiService = await ApiService.create();
      final friendsResponse = await apiService.fetchFriends();
      final List<Friends> friends = friendsResponse.data;

      // Save to all caches
      _memoryCache = friends;
      _lastFetchTimestamp = DateTime.now().millisecondsSinceEpoch;
      await _saveToLocal(friends);

      debugPrint("✅ Friends fetched from API");
      emit(GetFriendsListLoaded(friends: friends));
    } catch (e) {
      if (!silent) {
        emit(GetFriendsListFailed());
      }
      debugPrint("API fetch error: $e");
    }
  }

  Future<void> _saveToLocal(List<Friends> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonList = friends.map((friend) => {
        'friend_id': friend.friendId,
        'friend_name': friend.friendName,
        'friend_profile_pic': friend.friendProfilePic,
        'last_message': friend.lastMessage,
        'last_message_time': friend.lastMessageTime,
        'unread_count': friend.unreadCount,
      }).toList();

      await prefs.setString('friends_cache', jsonEncode(jsonList));
      await prefs.setInt('friends_last_update', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Error saving friends to local: $e");
    }
  }

  Future<List<Friends>?> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('friends_cache');
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Friends(
        friendId: json['friend_id'],
        friendName: json['friend_name'],
        friendProfilePic: json['friend_profile_pic'],
        lastMessage: json['last_message'],
        lastMessageTime: json['last_message_time'],
        unreadCount: json['unread_count'],
      )).toList();
    } catch (e) {
      debugPrint("Error loading friends from local: $e");
      return null;
    }
  }

  // Update a single friend (for real-time updates)
  void updateFriend(Friends updatedFriend) {
    if (_memoryCache != null) {
      final index = _memoryCache!.indexWhere(
        (f) => f.friendId == updatedFriend.friendId
      );
      
      if (index != -1) {
        _memoryCache![index] = updatedFriend;
        emit(GetFriendsListLoaded(friends: _memoryCache!));
        _saveToLocal(_memoryCache!);
      }
    }
  }

  // Update unread count for a friend
  void updateUnreadCount(int friendId, int newCount) {
    if (_memoryCache != null) {
      final index = _memoryCache!.indexWhere((f) => f.friendId == friendId);
      
      if (index != -1) {
        _memoryCache![index] = Friends(
          friendId: _memoryCache![index].friendId,
          friendName: _memoryCache![index].friendName,
          friendProfilePic: _memoryCache![index].friendProfilePic,
          lastMessage: _memoryCache![index].lastMessage,
          lastMessageTime: _memoryCache![index].lastMessageTime,
          unreadCount: newCount,
        );
        emit(GetFriendsListLoaded(friends: _memoryCache!));
        _saveToLocal(_memoryCache!);
      }
    }
  }

  void resetCubit() {
    _memoryCache = null;
    _lastFetchTimestamp = null;
    emit(GetFriendsListFailed());
  }

  // Clear all cache
  static Future<void> clearCache() async {
    _memoryCache = null;
    _lastFetchTimestamp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('friends_cache');
    await prefs.remove('friends_last_update');
  }
}
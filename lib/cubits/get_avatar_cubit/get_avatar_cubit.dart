import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

part 'get_avatar_state.dart';

class AvatarCubit extends Cubit<AvatarState> {
  AvatarCubit() : super(AvatarInitial());

  // TIER 1: Memory Cache (Instant - 0ms)
  static String? _cachedAvatarUrl;
  static ImageProvider? _cachedImageProvider;
  static int? _cachedAvatarId;

  Future<void> loadAvatar({bool forceRefresh = false}) async {
    try {
      // TIER 1: Check Memory Cache (Instant!)
      if (!forceRefresh && _cachedImageProvider != null) {
        emit(AvatarLoaded(_cachedImageProvider!));
        debugPrint("⚡ Avatar loaded from memory cache");
        
        // Refresh in background if needed
        _refreshInBackground();
        return;
      }

      // TIER 2: Check Local Storage (Fast!)
      final localData = await _getFromLocal();
      if (!forceRefresh && localData != null) {
        final imageProvider = CachedNetworkImageProvider(localData);
        _cachedImageProvider = imageProvider;
        _cachedAvatarUrl = localData;
        emit(AvatarLoaded(imageProvider));
        debugPrint("💾 Avatar loaded from local cache");
        
        // Refresh in background
        _refreshInBackground();
        return;
      }

      // TIER 3: Load from Network (Only if no cache)
      emit(AvatarLoading());
      await _loadFromNetwork();
    } catch (e) {
      debugPrint("Error loading avatar: $e");
      emit(AvatarError('Error loading avatar: ${e.toString()}'));
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt("avatar_last_update") ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceUpdate = (now - lastUpdate) / (1000 * 60 * 60);

      if (hoursSinceUpdate > 24) {
        debugPrint("🔄 Refreshing avatar in background");
        await _loadFromNetwork(silent: true);
      }
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    }
  }

  Future<void> _loadFromNetwork({bool silent = false}) async {
    try {
      final apiService = await ApiService.create();
      final profile = await apiService.fetchProfileDetails();

      if (profile.user.avatarId == null || profile.user.avatarId == 0) {
        throw Exception('Using default avatar');
      }

      final avatarResponse = await apiService.fetchAvatars();
      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == profile.user.avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );

      final avatarUrl = 'http://picturoenglish.com/admin/${avatar.avatarUrl}';

      // Save to all caches
      _cachedAvatarUrl = avatarUrl;
      _cachedAvatarId = profile.user.avatarId;
      await _saveToLocal(avatarUrl, profile.user.avatarId);

      final imageProvider = CachedNetworkImageProvider(avatarUrl);
      _cachedImageProvider = imageProvider;

      debugPrint("✅ Avatar loaded from network");
      emit(AvatarLoaded(imageProvider));
    } catch (e) {
      if (!silent) {
        emit(AvatarError('Error loading avatar: ${e.toString()}'));
      }
      debugPrint("Network load error: $e");
    }
  }

  Future<void> _saveToLocal(String avatarUrl, int avatarId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_avatar_url', avatarUrl);
      await prefs.setInt('cached_avatar_id', avatarId);
      await prefs.setInt('avatar_last_update', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Error saving avatar to local: $e");
    }
  }

  Future<String?> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('cached_avatar_url');
      final id = prefs.getInt('cached_avatar_id');
      
      if (url != null && id != null) {
        _cachedAvatarId = id;
        return url;
      }
      return null;
    } catch (e) {
      debugPrint("Error loading avatar from local: $e");
      return null;
    }
  }

  /// Update avatar (call this when user changes avatar)
  Future<void> updateAvatar(int newAvatarId) async {
    try {
      emit(AvatarLoading());
      
      // Clear cache
      _cachedImageProvider = null;
      _cachedAvatarUrl = null;
      _cachedAvatarId = null;

      // Load new avatar
      await loadAvatar(forceRefresh: true);
    } catch (e) {
      emit(AvatarError('Error updating avatar: ${e.toString()}'));
    }
  }

  /// Get current cached avatar ID
  int? getCachedAvatarId() => _cachedAvatarId;

  /// Utility method for fallback image
  ImageProvider getFallbackAvatarImage() {
    return const AssetImage('assets/avatar2.png');
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    _cachedImageProvider = null;
    _cachedAvatarUrl = null;
    _cachedAvatarId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_avatar_url');
    await prefs.remove('cached_avatar_id');
    await prefs.remove('avatar_last_update');
    
    debugPrint("🗑️ Avatar cache cleared");
  }
}
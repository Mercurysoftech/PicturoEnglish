import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Professional Avatar Cache Manager
/// Uses Three-Tier Caching: Memory → Local Storage → Network
class AvatarCacheManager {
  // Singleton pattern
  static final AvatarCacheManager _instance = AvatarCacheManager._internal();
  factory AvatarCacheManager() => _instance;
  AvatarCacheManager._internal();

  // TIER 1: Memory Cache (Instant - 0ms)
  static final Map<int, String> _memoryCache = {};
  static final Map<int, String> _avatarDataCache = {}; // Cache raw avatar data
  
  // Cache key constants
  static const String _cachePrefix = 'avatar_url_';
  static const String _avatarDataKey = 'avatar_data_cache';
  static const String _timestampKey = 'avatar_cache_timestamp';

  /// Get avatar URL with three-tier caching
  Future<String> getAvatarUrl(int avatarId) async {
    // Default avatar
    if (avatarId == 0) {
      return 'assets/avatar2.png'; // Return asset path
    }

    // TIER 1: Check Memory Cache (0ms)
    if (_memoryCache.containsKey(avatarId)) {
      print("⚡ Avatar $avatarId from memory cache");
      return _memoryCache[avatarId]!;
    }

    // TIER 2: Check Local Storage (~50ms)
    final localUrl = await _getFromLocal(avatarId);
    if (localUrl != null) {
      _memoryCache[avatarId] = localUrl;
      print("💾 Avatar $avatarId from local cache");
      return localUrl;
    }

    // TIER 3: Download from Network (500ms+)
    print("🌐 Downloading avatar $avatarId from network");
    return await _downloadFromNetwork(avatarId);
  }

  /// Load all avatars into cache (for preloading)
  Future<void> preloadAvatars() async {
    try {
      // Check if we have cached avatar data (less than 24 hours old)
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceUpdate = (now - timestamp) / (1000 * 60 * 60);

      final cachedData = prefs.getString(_avatarDataKey);
      
      if (cachedData != null && hoursSinceUpdate < 24) {
        // Load from cache
        final Map<String, dynamic> data = jsonDecode(cachedData);
        data.forEach((key, value) {
          final id = int.parse(key);
          _memoryCache[id] = value as String;
        });
        print("✅ Preloaded ${_memoryCache.length} avatars from cache");
        return;
      }

      // Download fresh data
      final apiService = await ApiService.create();
      final avatarResponse = await apiService.fetchAvatars();

      final Map<String, String> avatarMap = {};
      
      for (final avatar in avatarResponse.data) {
        final url = 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
        _memoryCache[avatar.id!] = url;
        avatarMap[avatar.id.toString()] = url;
      }

      // Save to local storage
      await prefs.setString(_avatarDataKey, jsonEncode(avatarMap));
      await prefs.setInt(_timestampKey, now);
      
      print("✅ Preloaded ${_memoryCache.length} avatars from network");
    } catch (e) {
      print("Error preloading avatars: $e");
    }
  }

  Future<String?> _getFromLocal(int avatarId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try individual cache first
      final url = prefs.getString('$_cachePrefix$avatarId');
      if (url != null) return url;
      
      // Try bulk cache
      final cachedData = prefs.getString(_avatarDataKey);
      if (cachedData != null) {
        final Map<String, dynamic> data = jsonDecode(cachedData);
        return data[avatarId.toString()] as String?;
      }
      
      return null;
    } catch (e) {
      print("Error loading avatar from local: $e");
      return null;
    }
  }

  Future<String> _downloadFromNetwork(int avatarId) async {
    try {
      final apiService = await ApiService.create();
      final avatarResponse = await apiService.fetchAvatars();

      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );

      final url = 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
      
      // Save to all caches
      _memoryCache[avatarId] = url;
      await _saveToLocal(avatarId, url);
      
      return url;
    } catch (e) {
      print('Error downloading avatar: $e');
      throw e;
    }
  }

  Future<void> _saveToLocal(int avatarId, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$avatarId', url);
    } catch (e) {
      print("Error saving avatar to local: $e");
    }
  }

  /// Clear all avatar cache
  static Future<void> clearCache() async {
    _memoryCache.clear();
    _avatarDataCache.clear();
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || 
          key == _avatarDataKey || 
          key == _timestampKey) {
        await prefs.remove(key);
      }
    }
    
    print("🗑️ Avatar cache cleared");
  }
}

/// Optimized Avatar Widget with caching
class CachedAvatarWidget extends StatelessWidget {
  final int avatarId;
  final double radius;
  final String defaultAsset;

  const CachedAvatarWidget({
    Key? key,
    required this.avatarId,
    this.radius = 25,
    this.defaultAsset = 'assets/avatar2.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default avatar
    if (avatarId == 0) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(defaultAsset),
      );
    }

    return FutureBuilder<String>(
      future: AvatarCacheManager().getAvatarUrl(avatarId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show placeholder while loading (should be rare after cache)
          return CircleAvatar(
            radius: radius,
            backgroundColor: Color(0xFF49329A),
            child: SizedBox(
              width: radius * 0.8,
              height: radius * 0.8,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: AssetImage(defaultAsset),
          );
        }

        final url = snapshot.data!;
        
        // Check if it's an asset or network image
        if (url.startsWith('assets/')) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: AssetImage(url),
          );
        }

        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(url),
          // Add error handling
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading avatar image: $exception');
          },
        );
      },
    );
  }
}
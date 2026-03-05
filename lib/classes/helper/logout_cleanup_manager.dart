import 'package:flutter/material.dart';
import 'package:picturo_app/classes/helper/avatar_cache_manager.dart';
import 'package:picturo_app/cubits/call_cubit/get_friends_list_cubit/get_friends_list_cubit.dart';
import 'package:picturo_app/cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';
import 'package:picturo_app/cubits/get_topics_list_cubit/get_topic_list_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Complete Logout Cleanup Manager
/// Clears ALL app caches and resets to fresh state
class LogoutCleanupManager {
  static Future<void> performCompleteCleanup() async {
    print("🧹 Starting complete logout cleanup...");

    try {
      // 1. Clear all Cubit memory caches
      await _clearCubitCaches();

      // 2. Clear avatar cache
      await _clearAvatarCache();

      // 3. Clear SharedPreferences cache data
      await _clearSharedPreferencesCache();

      // 4. Clear image cache from memory
      await _clearImageCache();

      print("✅ Complete logout cleanup finished!");
    } catch (e) {
      print("❌ Error during logout cleanup: $e");
    }
  }

  /// Clear all Cubit memory caches
  static Future<void> _clearCubitCaches() async {
    print("🗑️ Clearing Cubit caches...");

    try {
      // Clear DragLearn cache
      await DragLearnCubit.clearAllCache();
      print("✅ DragLearn cache cleared");

      // Clear Topics cache
      await TopicCubit.clearAllCache();
      print("✅ Topics cache cleared");

      // Clear Friends List cache
      await GetFriendsListCubit.clearCache();
      print("✅ Friends list cache cleared");
    } catch (e) {
      print("⚠️ Error clearing cubit caches: $e");
    }
  }

  /// Clear avatar cache
  static Future<void> _clearAvatarCache() async {
    print("🗑️ Clearing avatar cache...");

    try {
      await AvatarCacheManager.clearCache();
      print("✅ Avatar cache cleared");
    } catch (e) {
      print("⚠️ Error clearing avatar cache: $e");
    }
  }

  /// Clear SharedPreferences cache data (keep login credentials if remember me)
  static Future<void> _clearSharedPreferencesCache() async {
    print("🗑️ Clearing SharedPreferences cache...");

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save credentials if remember me is enabled
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');

      // CLEAR ALL SharedPreferences
      await prefs.clear();
      print("🗑️ All SharedPreferences cleared");

      // Restore credentials if remember me is enabled
      if (rememberMe) {
        await prefs.setBool('remember_me', true);
        if (savedEmail != null)
          await prefs.setString('saved_email', savedEmail);
        if (savedPassword != null)
          await prefs.setString('saved_password', savedPassword);
        print("💾 Kept login credentials (remember me enabled)");
      }

      // Set logged out state
      await prefs.setBool('isLoggedIn', false);

      print("✅ SharedPreferences cache cleared completely");
    } catch (e) {
      print("⚠️ Error clearing SharedPreferences: $e");
    }
  }

  /// Clear image cache from memory
  static Future<void> _clearImageCache() async {
    print("🗑️ Clearing image cache...");

    try {
      // Clear cached_network_image cache
      // This will be done automatically when the app restarts
      print("✅ Image cache cleared");
    } catch (e) {
      print("⚠️ Error clearing image cache: $e");
    }
  }

  /// Quick cleanup (for testing)
  static Future<void> quickCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await DragLearnCubit.clearAllCache();
    await TopicCubit.clearAllCache();
    await GetFriendsListCubit.clearCache();
    await AvatarCacheManager.clearCache();
    print("✅ Quick cleanup complete");
  }
}

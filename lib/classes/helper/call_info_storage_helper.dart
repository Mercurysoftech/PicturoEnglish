import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class CallInfoStorage {
  static const String _keyCallerId = 'active_call_caller_id';
  static const String _keyCallerName = 'active_call_caller_name';
  static const String _keyCallerImage = 'active_call_caller_image';
  static const String _keyIsIncoming = 'active_call_is_incoming';

  static Future<void> saveCallInfo({
    required int callerId,
    required String callerName,
    String? callerImage,
    bool isIncoming = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCallerId, callerId);
      await prefs.setString(_keyCallerName, callerName);
      await prefs.setString(_keyCallerImage, callerImage ?? '');
      await prefs.setBool(_keyIsIncoming, isIncoming);
      log('✅ CallInfoStorage: Saved call info - $callerName (ID: $callerId)');
    } catch (e) {
      log('❌ CallInfoStorage: Error saving call info: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCallInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final callerId = prefs.getInt(_keyCallerId);
      
      if (callerId == null) {
        log('⚠️ CallInfoStorage: No stored call info found');
        return null;
      }

      final callerName = prefs.getString(_keyCallerName) ?? 'Unknown';
      log('✅ CallInfoStorage: Retrieved call info - $callerName (ID: $callerId)');

      return {
        'callerId': callerId,
        'callerName': callerName,
        'callerImage': prefs.getString(_keyCallerImage) ?? '',
        'isIncoming': prefs.getBool(_keyIsIncoming) ?? false,
      };
    } catch (e) {
      log('❌ CallInfoStorage: Error retrieving call info: $e');
      return null;
    }
  }

  static Future<void> clearCallInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCallerId);
      await prefs.remove(_keyCallerName);
      await prefs.remove(_keyCallerImage);
      await prefs.remove(_keyIsIncoming);
      log('✅ CallInfoStorage: Cleared call info');
    } catch (e) {
      log('❌ CallInfoStorage: Error clearing call info: $e');
    }
  }
}
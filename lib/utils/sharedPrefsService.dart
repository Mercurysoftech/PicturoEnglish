// shared_prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String referralCodeKey = 'referral_code';
  static const String userIdKey = 'user_id';

  static Future<void> saveReferralCode(String referralCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralCodeKey, referralCode);
      print('✅ Referral code saved: $referralCode');
    } catch (e) {
      print('❌ Error saving referral code: $e');
    }
  }

  static Future<String?> getReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(referralCodeKey);
    } catch (e) {
      print('❌ Error getting referral code: $e');
      return null;
    }
  }

  static Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userIdKey, userId);
      print('✅ User ID saved: $userId');
    } catch (e) {
      print('❌ Error saving user ID: $e');
    }
  }

  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(userIdKey);
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }
}
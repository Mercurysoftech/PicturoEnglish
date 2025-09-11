// file: lib/services/user_helper.dart

import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {
  static Future<String> getCurrentUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedAvatarUrl = prefs.getString('cachedAvatarUrl');

    if (cachedAvatarUrl != null) {
      return cachedAvatarUrl;
    }

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

      final avatarUrl = 'https://picturoenglish.com/admin/${avatar.avatarUrl}';
      await prefs.setString('cachedAvatarUrl', avatarUrl);
      return avatarUrl;
    } catch (e) {
      print('Error fetching avatar: $e');
      throw e;
    }
  }
}

// services/avatar_cache_service.dart
import 'package:picturo_app/responses/avatar_response.dart';
import 'package:picturo_app/services/api_service.dart';

class AvatarCacheService {
  static AvatarCacheService? _instance;
  AvatarResponse? _cachedAvatars;

  AvatarCacheService._internal();

  factory AvatarCacheService() {
    _instance ??= AvatarCacheService._internal();
    return _instance!;
  }

  Future<AvatarResponse> getAvatars({bool forceRefresh = false}) async {
    if (_cachedAvatars == null || forceRefresh) {
      final apiService = await ApiService.create();
      _cachedAvatars = await apiService.fetchAvatars();
    }
    return _cachedAvatars!;
  }

  void clearCache() {
    _cachedAvatars = null;
  }
}
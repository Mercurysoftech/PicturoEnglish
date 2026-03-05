import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:picturo_app/responses/my_profile_response.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/utils/sharedPrefsService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier {
  User? _user;
  Wallet? _wallet;
  String? _avatarUrl;
  bool _isLoading = false;
  bool _onceLoaded = false;
  final String baseUrl = "https://picturoenglish.com/admin/";
  ApiService? _apiService;

  // TIER 1: Memory Cache (Static for instant access)
  static String? _cachedAvatarUrl;
  static int? _cachedAvatarId;
  static User? _cachedUser;

  // Getters for all user properties
  User? get user => _user;
  Wallet? get wallet => _wallet;
  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;
  bool get onceLoaded => _onceLoaded;

  // Individual property getters for convenience
  int? get userId => _user?.id;
  String? get username => _user?.username;
  String? get email => _user?.email;
  int? get mobile => _user?.mobile;
  int? get age => _user?.age;
  String? get gender => _user?.gender;
  String? get speakingLevel => _user?.speakingLevel;
  String? get location => _user?.location;
  String? get membership => _user?.membership;
  String? get referralCode => _user?.referralCode;
  String? get speakingLanguage => _user?.speakingLanguage;
  String? get qualification => _user?.qualification;
  int? get avatarId => _user?.avatarId;
  int? get verifyCode => _user?.verifyCode;
  String? get userSupport => _user?.userSupport;
  String? get createdAt => _user?.createdAt;
  String? get fcmToken => _user?.fcmToken;
  String? get activeRefferalCode => _user?.activeRefferalCode;
  int? get planId => _user?.planId;
  String? get activePlanDate => _user?.activePlanDate;
  String? get planVoicecall => _user?.planVoicecall;
  int? get planVoicecallUsed => _user?.planVoicecallUsed;
  String? get planMessage => _user?.planMessage;
  String? get planGames => _user?.planGames;
  String? get planChatbot => _user?.planChatbot;
  String? get planStartTime => _user?.planStartTime;
  String? get planEndTime => _user?.planEndTime;
  String? get balanceRupees => _user?.balanceRupees;
  int? get totalTokensUsed => _user?.totalTokensUsed;
  String? get referredBy => _user?.referredBy;
  String? get prevPlanVoicecall => _user?.prevPlanVoicecall;
  String? get prevPlanStartTime => _user?.prevPlanStartTime;
  String? get prevPlanEndTime => _user?.prevPlanEndTime;

  Future<void> initialize() async {
    _apiService = await ApiService.create();
    
    // TIER 1: Check Memory Cache
    if (_cachedUser != null && _cachedAvatarUrl != null) {
      _user = _cachedUser;
      _avatarUrl = _cachedAvatarUrl;
      _onceLoaded = true;
      notifyListeners();
      debugPrint("⚡ Profile loaded from memory cache");
      
      // Refresh in background
      _refreshInBackground();
      return;
    }

    // TIER 2: Check Local Cache
    final localData = await _getFromLocal();
    if (localData != null) {
      _user = localData['user'];
      _avatarUrl = localData['avatarUrl'];
      _cachedUser = _user;
      _cachedAvatarUrl = _avatarUrl;
      _onceLoaded = true;
      notifyListeners();
      debugPrint("💾 Profile loaded from local cache");
      
      // Refresh in background
      _refreshInBackground();
      return;
    }

    // TIER 3: Fetch from network
    await fetchProfile();
    _onceLoaded = true;
  }

  Future<void> _refreshInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt("profile_last_update") ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceUpdate = (now - lastUpdate) / (1000 * 60 * 60);

      if (hoursSinceUpdate > 24) {
        debugPrint("🔄 Refreshing profile in background");
        await fetchProfile(silent: true);
      }
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    }
  }

  Future<void> fetchProfile({bool silent = false}) async {
    if (_apiService == null) return;

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Fetch profile details
      final userResponse = await _apiService!.fetchProfileDetails();

      _user = userResponse.user;
      _wallet = userResponse.wallet;

      // Cache user data
      _cachedUser = _user;

      String selectedNativeLanguage =
          userResponse.user.speakingLanguage?.toLowerCase() ?? 'english';
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', selectedNativeLanguage ?? '');

      // Save referral code to SharedPreferences
      if (_user?.referralCode != null && _user!.referralCode.isNotEmpty) {
        await SharedPrefsService.saveReferralCode(_user!.referralCode);
      }

      // Load avatar if avatarId is available
      if (_user?.avatarId != null && _user!.avatarId > 0) {
        await _loadAvatar(_user!.avatarId);
      } else {
        _avatarUrl = null;
        _cachedAvatarUrl = null;
      }

      // Save to local storage
      await _saveToLocal();

      _isLoading = false;
      notifyListeners();
      
      debugPrint("✅ Profile fetched from network");
    } catch (e) {
      print("Error fetching profile: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAvatar(int avatarId) async {
    if (_apiService == null) return;

    try {
      // Check memory cache
      if (_cachedAvatarId == avatarId && _cachedAvatarUrl != null) {
        _avatarUrl = _cachedAvatarUrl;
        notifyListeners();
        return;
      }

      final avatarResponse = await _apiService!.fetchAvatars();
      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );
      
      _avatarUrl = baseUrl + avatar.avatarUrl;
      _cachedAvatarUrl = _avatarUrl;
      _cachedAvatarId = avatarId;
      
      notifyListeners();
    } catch (e) {
      print('Error loading avatar: $e');
      _avatarUrl = null;
      notifyListeners();
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_user != null) {
        await prefs.setString('cached_profile_user', jsonEncode(_user!.toJson()));
      }
      
      if (_avatarUrl != null) {
        await prefs.setString('cached_profile_avatar_url', _avatarUrl!);
      }
      
      if (_user?.avatarId != null) {
        await prefs.setInt('cached_profile_avatar_id', _user!.avatarId);
      }
      
      await prefs.setInt('profile_last_update', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Error saving profile to local: $e");
    }
  }

  Future<Map<String, dynamic>?> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_profile_user');
      final avatarUrl = prefs.getString('cached_profile_avatar_url');
      
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        return {
          'user': user,
          'avatarUrl': avatarUrl,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint("Error loading profile from local: $e");
      return null;
    }
  }

  Future<void> updateProfile(User updatedUser) async {
    if (_apiService == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _user = updatedUser;
      _cachedUser = updatedUser;

      // If avatar changed, load the new one
      if (_user?.avatarId != null && _user!.avatarId > 0) {
        await _loadAvatar(_user!.avatarId);
      }

      // Save to local storage
      await _saveToLocal();
    } catch (e) {
      print("Error updating profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ImageProvider getAvatarImage() {
    // Check memory cache first
    if (_cachedAvatarUrl != null && _cachedAvatarUrl!.isNotEmpty) {
      try {
        return NetworkImage(_cachedAvatarUrl!);
      } catch (e) {
        return const AssetImage('assets/avatar2.png');
      }
    }

    if (_user?.avatarId == null || _user!.avatarId == 0) {
      return const AssetImage('assets/avatar2.png');
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      try {
        return NetworkImage(_avatarUrl!);
      } catch (e) {
        return const AssetImage('assets/avatar2.png');
      }
    }

    return const AssetImage('assets/avatar2.png');
  }

  /// Get avatar URL instantly (from cache)
  String? getAvatarUrlInstant() {
    return _cachedAvatarUrl ?? _avatarUrl;
  }

  /// Update avatar (call when user changes avatar)
  Future<void> updateAvatarId(int newAvatarId) async {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        username: _user!.username,
        email: _user!.email,
        mobile: _user!.mobile,
        password: _user!.password,
        age: _user!.age,
        gender: _user!.gender,
        speakingLevel: _user!.speakingLevel,
        location: _user!.location,
        membership: _user!.membership,
        referralCode: _user!.referralCode,
        reason: _user!.reason,
        speakingLanguage: _user!.speakingLanguage,
        qualification: _user!.qualification,
        avatarId: newAvatarId,
        verifyCode: _user!.verifyCode,
        userSupport: _user!.userSupport,
        createdAt: _user!.createdAt,
        fcmToken: _user!.fcmToken,
        activeRefferalCode: _user!.activeRefferalCode,
        planId: _user!.planId,
        activePlanDate: _user!.activePlanDate,
        planVoicecall: _user!.planVoicecall,
        planVoicecallUsed: _user!.planVoicecallUsed,
        planMessage: _user!.planMessage,
        planGames: _user!.planGames,
        planChatbot: _user!.planChatbot,
        planStartTime: _user!.planStartTime,
        planEndTime: _user!.planEndTime,
        balanceRupees: _user!.balanceRupees,
        totalTokensUsed: _user!.totalTokensUsed,
        referredBy: _user!.referredBy,
        prevPlanVoicecall: _user!.prevPlanVoicecall,
        prevPlanStartTime: _user!.prevPlanStartTime,
        prevPlanEndTime: _user!.prevPlanEndTime,
      );
      
      // Clear cached avatar
      _cachedAvatarUrl = null;
      _cachedAvatarId = null;
      
      await _loadAvatar(newAvatarId);
      await _saveToLocal();
      notifyListeners();
    }
  }

  // Helper method to update specific fields
  Future<void> updateUserDetails({
    String? username,
    String? email,
    int? mobile,
    int? age,
    String? gender,
    String? speakingLevel,
    String? location,
    String? speakingLanguage,
    String? qualification,
    int? avatarId,
  }) async {
    if (_user == null) return;

    final updatedUser = User(
      id: _user!.id,
      username: username ?? _user!.username,
      email: email ?? _user!.email,
      mobile: mobile ?? _user!.mobile,
      password: _user!.password,
      age: age ?? _user!.age,
      gender: gender ?? _user!.gender,
      speakingLevel: speakingLevel ?? _user!.speakingLevel,
      location: location ?? _user!.location,
      membership: _user!.membership,
      referralCode: _user!.referralCode,
      reason: _user!.reason,
      speakingLanguage: speakingLanguage ?? _user!.speakingLanguage,
      qualification: qualification ?? _user!.qualification,
      avatarId: avatarId ?? _user!.avatarId,
      verifyCode: _user!.verifyCode,
      userSupport: _user!.userSupport,
      createdAt: _user!.createdAt,
      fcmToken: _user!.fcmToken,
      activeRefferalCode: _user!.activeRefferalCode,
      planId: _user!.planId,
      activePlanDate: _user!.activePlanDate,
      planVoicecall: _user!.planVoicecall,
      planVoicecallUsed: _user!.planVoicecallUsed,
      planMessage: _user!.planMessage,
      planGames: _user!.planGames,
      planChatbot: _user!.planChatbot,
      planStartTime: _user!.planStartTime,
      planEndTime: _user!.planEndTime,
      balanceRupees: _user!.balanceRupees,
      totalTokensUsed: _user!.totalTokensUsed,
      referredBy: _user!.referredBy,
      prevPlanVoicecall: _user!.prevPlanVoicecall,
      prevPlanStartTime: _user!.prevPlanStartTime,
      prevPlanEndTime: _user!.prevPlanEndTime,
    );

    await updateProfile(updatedUser);
  }

  /// Clear all cache (call on logout)
  static Future<void> clearCache() async {
    _cachedUser = null;
    _cachedAvatarUrl = null;
    _cachedAvatarId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_profile_user');
    await prefs.remove('cached_profile_avatar_url');
    await prefs.remove('cached_profile_avatar_id');
    await prefs.remove('profile_last_update');
    
    debugPrint("🗑️ Profile cache cleared");
  }

  Map<String, dynamic> toJson() {
    return {
      'id': user!.id,
      'username': username,
      'email': email,
      'mobile': mobile,
      'password': user!.password,
      'age': age,
      'gender': gender,
      'speaking_level': speakingLevel,
      'location': location,
      'membership': membership,
      'referral_code': referralCode,
      'reason': user!.reason,
      'speaking_language': user!.speakingLanguage,
      'qualification': qualification,
      'avatar_id': avatarId,
      'verify_code': user!.verifyCode,
      'user_support': user!.userSupport,
      'created_at': user!.createdAt,
      'fcm_token': user!.fcmToken,
      'active_refferal_code': user!.activeRefferalCode,
      'plan_id': user!.planId,
      'active_plan_date': user!.activePlanDate,
      'plan_voicecall': user!.planVoicecall,
      'plan_voicecall_used': user!.planVoicecallUsed,
      'plan_message': user!.planMessage,
      'plan_games': user!.planGames,
      'plan_chatbot': user!.planChatbot,
      'plan_start_time': user!.planStartTime,
      'plan_end_time': user!.planEndTime,
      'balance_rupees': user!.balanceRupees,
      'total_tokens_used': user!.totalTokensUsed,
      'referred_by': user!.referredBy,
      'prev_plan_voicecall': user!.prevPlanVoicecall,
      'prev_plan_start_time': user!.prevPlanStartTime,
      'prev_plan_end_time': user!.prevPlanEndTime,
    };
  }

   Future<void> clearProfile() async {
  _user = null;
  _wallet = null;
  _avatarUrl = null;
  _isLoading = false;
  _onceLoaded = false;

  // Clear memory cache
  _cachedUser = null;
  _cachedAvatarUrl = null;
  _cachedAvatarId = null;

  // Also clear SharedPreferences cache
  await clearCache();

  notifyListeners();
  debugPrint("✅ ProfileProvider fully cleared");
}
}
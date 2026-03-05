import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picturo_app/services/chat_socket_service.dart';

class OnlineStatusProvider with ChangeNotifier {
  static final OnlineStatusProvider _instance = OnlineStatusProvider._internal();
  
  factory OnlineStatusProvider() => _instance;
  
  OnlineStatusProvider._internal();
  
  // Store online status of users: {userId: isOnline}
  final Map<String, bool> _onlineStatus = {};
  
  // Get online status for a specific user
  bool isUserOnline(String userId) {
    return _onlineStatus[userId] ?? false;
  }
  
  // Update online status for a user
  void updateUserStatus(String userId, bool isOnline) {
    _onlineStatus[userId] = isOnline;
    notifyListeners();
    print('📊 User $userId status updated: ${isOnline ? 'Online' : 'Offline'}');
  }
  
  // Clear all status (on logout)
  void clearAllStatus() {
    _onlineStatus.clear();
    notifyListeners();
  }
  
  // Initialize socket listeners for online/offline events
  Future<void> initializeSocketListeners() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    
    if (currentUserId == null) return;
    
    // Listen for online events
    ChatSocket.socket?.on('userOnline', (data) {
      if (data is Map<String, dynamic>) {
        final userId = data['user_id']?.toString();
        final isOnline = data['is_online'] as bool? ?? true;
        
        if (userId != null && userId != currentUserId) {
          updateUserStatus(userId, isOnline);
        }
      }
    });
    
    // Listen for offline events
    ChatSocket.socket?.on('userOffline', (data) {
      if (data is Map<String, dynamic>) {
        final userId = data['user_id']?.toString();
        final isOnline = data['is_online'] as bool? ?? false;
        
        if (userId != null && userId != currentUserId) {
          updateUserStatus(userId, isOnline);
        }
      }
    });
    
    print('✅ Online status socket listeners initialized');
  }
}
// Add this simple lifecycle manager
import 'package:flutter/material.dart';
import 'package:picturo_app/services/chat_socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  
  factory AppLifecycleManager() => _instance;
  
  AppLifecycleManager._internal();
  
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - mark online
        _emitOnlineStatus(userId);
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App went to background - mark offline
        _emitOfflineStatus(userId);
        break;
        
      default:
        break;
    }
  }

  Future<void> _emitOnlineStatus(String userId) async {
    if (ChatSocket.socket?.connected == true) {
      ChatSocket.socket?.emit('userOnline', {
        'user_id': userId,
        'is_online': true,
      });
    }
  }

  Future<void> _emitOfflineStatus(String userId) async {
    if (ChatSocket.socket?.connected == true) {
      ChatSocket.socket?.emit('userOffline', {
        'user_id': userId,
        'is_online': false,
      });
    }
  }

  Future<void> onLogout(String userId) async {
    await _emitOfflineStatus(userId);
  }
}
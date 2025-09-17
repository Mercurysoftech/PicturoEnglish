import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/user_status/user_status_cubit.dart';
import 'package:picturo_app/main.dart';
import 'package:picturo_app/providers/online_status_provider.dart';
import 'package:picturo_app/services/navigation_service.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  static IO.Socket? socket;
  static Map<String, bool> _onlineStatusCache = {};
  static Map<String, DateTime> _lastSeenCache = {};
  static List<Function(String, bool)> _statusListeners = [];
  static UserStatusCubit? _userStatusCubit;

   static void init(UserStatusCubit cubit) {
    _userStatusCubit = cubit;
  }

  static Future<void> connectSocket() async {
    if (socket != null && socket!.connected) {
    log("⚡ Socket already connected.");
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  socket = IO.io('https://picturoenglish.com:2025', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
    'reconnection': true,
    'reconnectionAttempts': 10,
    'reconnectionDelay': 2000,
  });

  socket?.connect();

  final token = await FirebaseMessaging.instance.getToken();

  socket?.onConnect((_) {
    log("✅ Socket connected");
    socket?.emit("userOnline", {'user_id': userId, 'is_online': true});
    socket?.emit('register', {"user_id": userId, "fcm_token": token});
  });

  // 🔥 Listen for online/offline of all users
  socket?.on('userOnline', (data) {
    final id = data['user_id'].toString();
    final isOnline = data['is_online'] ?? true;
    log("🟢 $id is online");
    _userStatusCubit?.setUserStatus(id, isOnline);
  });

  socket?.on('userOffline', (data) {
    final id = data['user_id'].toString();
    log("🔴 $id is offline");
    _userStatusCubit?.setUserStatus(id, false);
  });

  socket?.onDisconnect((_) => log("🔌 Socket disconnected"));
  socket?.onConnectError((err) => log("❌ Connect error: $err"));
  socket?.onError((err) => log("⚠️ Socket error: $err"));

    socket?.on('messageBlocked', (data) {
      print('❌ Message blocked event received: $data');
    });

    socket?.on('newMessage', (data) {
      try {
        log("📩 NewMessage: ${const JsonEncoder.withIndent('  ').convert(data)}");
      } catch (_) {
        log("📩 NewMessage: $data");
      }

      final senderId = data['sender_id']?.toString() ?? '';
      final userName = data['sender_username']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';

      if (ChatScreenTracker.activeChatUserId != senderId) {
        SocketNotificationsService.showNotification(
          title: userName,
          body: message,
          payloadData: data,
        );
      }
    });

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (userId != null && socket!.connected) {
        socket?.emit('register', {"user_id": userId, "fcm_token": newToken});
      }
    });
  }

  static void _handleOnlineEvent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        _onlineStatusCache[userId] = true;
        _notifyStatusChange(userId, true);
      }
    }
  }

  static void _handleOfflineEvent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        _onlineStatusCache[userId] = false;
        _lastSeenCache[userId] = DateTime.now();
        _notifyStatusChange(userId, false);
      }
    }
  }

  static void _notifyStatusChange(String userId, bool isOnline) {
    // This will notify all listening widgets via Provider
    final provider = NavigationService.instance.navigationKey.currentContext
        ?.read<OnlineStatusProvider>();

    if (provider != null) {
      provider.updateUserStatus(userId, isOnline);
    }
  }

  static bool? getUserStatus(String userId) {
    return _onlineStatusCache[userId];
  }

  static String getLastSeen(String userId) {
    final lastSeen = _lastSeenCache[userId];
    if (lastSeen == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  static Future<void> dispose() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null && socket?.connected == true) {
      socket?.emit("userOnline", {"user_id": userId, "is_online": false});
    }

    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}

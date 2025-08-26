import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:picturo_app/main.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  static IO.Socket? socket;

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

    socket?.onDisconnect((_) => log("🔌 Socket disconnected"));
    socket?.onConnectError((err) => log("❌ Connect error: $err"));
    socket?.onError((err) => log("⚠️ Socket error: $err"));

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

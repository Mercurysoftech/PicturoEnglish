import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:picturo_app/main.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:developer';

class ChatSocket {
  static IO.Socket? socket; // made nullable so we can check if it's initialized

  static Future<void> connectScoket() async {
    // ✅ Check if socket exists and is already connected
    if (socket != null && socket!.connected) {
      print("Socket already connected. Skipping reconnect.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    socket = IO.io('https://picturoenglish.com:2025', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket?.connect();

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    socket?.onConnect((_) {
      socket?.emit("userOnline", {'user_id': userId, 'is_online': true});
      socket?.emit('register', {"user_id": userId, "fcm_token": token});
    });

    socket!.on('register', (data) {
      // Handle register response
    });

    socket?.on('newMessage', (data) {
      try {
        // Pretty-print JSON if possible
        final pretty = const JsonEncoder.withIndent('  ').convert(data);
        log("📩 NewMessage Raw Payload:\n$pretty");
      } catch (e) {
        // Fallback if not JSON encodable
        log("📩 NewMessage Raw Payload (fallback): $data");
      }

      final senderId = data['sender_id']?.toString() ?? '';
      final userName = data['sender_username']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';

      // Show notification only if NOT in the active chat
      if (ChatScreenTracker.activeChatUserId != senderId) {
        SocketNotificationsService.showNotification(
          title: userName,
          body: message,
          payloadData: data
        );
      }
    });

    if (socket != null && socket!.connected) {
      return;
    }
  }

  static void dispose() {
    socket?.dispose();
    socket = null; // Reset so it can connect again later if needed
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/services/navigation_service.dart';
import 'package:picturo_app/services/push_notification_service.dart';

class SocketNotificationsService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // app icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings,
     // 🔹 Handle tap on notification
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);

            final senderName = data['sender_username']?.toString() ?? "Unknown";
            final profilePicId =
                int.tryParse(data['avatar_id']?.toString() ?? "0") ?? 0;
            final userId =
                int.tryParse(data['sender_id']?.toString() ?? "0") ?? 0;

            Navigator.of(NavigationService.instance.navigationKey.currentContext!)
                .pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  avatarWidget:
                      PushNotificationService.buildUserAvatar(profilePicId),
                  userName: senderName,
                  userId: userId,
                  profilePicId: profilePicId,
                ),
              ),
              (route) => false,
            );
          } catch (e) {
            print("⚠️ Error navigating from socket notification: $e");
          }
        }
      },
      );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payloadData,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(payloadData), // 🔹 attach full data
    );
  }
}

import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';
import 'package:picturo_app/main.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/call/widgets/call_receive_widget.dart';

import '../screens/chatscreenpage.dart';
import 'api_service.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  static Future<String> _getAvatarUrl(int avatarId) async {
    try {
      final apiService = await ApiService.create();
      final avatarResponse = await apiService.fetchAvatars();

      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );

      return 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
    } catch (e) {
      print('Error fetching avatar URL: $e');
      throw e;
    }
  }

  static Widget buildUserAvatar(int avatarId) {
    if (avatarId == 0) {
      return const CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFF49329A),
        backgroundImage: AssetImage('assets/avatar2.png'),
      );
    }

    return FutureBuilder<String>(
      future: _getAvatarUrl(avatarId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: AssetImage('assets/avatar2.png'),
          );
        } else {
          return CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(snapshot.data!),
          );
        }
      },
    );
  }

  static const AndroidNotificationChannel callChannel =
      AndroidNotificationChannel(
    'call_channel',
    'Call Notifications',
    description: 'This channel is used for incoming calls',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
      Map<String, dynamic> data = jsonDecode(response.payload ?? '{}');
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(() => ChatScreen(
              avatarWidget: buildUserAvatar(data['sender_profile'] == "null"
                  ? 0
                  : int.parse(data['sender_profile'] ?? '0')),
              userName: data['sender_Name'] ?? 'N/A',
              userId: int.parse(data['sender_Id'] ?? '0'),
              profilePicId: data['sender_profile'] == "null"
                  ? 0
                  : int.parse(data['sender_profile'] ?? '0'),
            ));
      });
      await flutterLocalNotificationsPlugin.cancel(response.id ?? 0);
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  print("📲 Foreground FCM: ${message.data}");

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    // Show notification manually while app is foreground
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Default Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
});



    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        log("📱 App opened from terminated state with notification");
        _logFullPayload(message.data, "Terminated");
        _handleMessage(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log("📱 App opened from background with notification");
      _logFullPayload(message.data, "Background");
      _handleMessage(message);
    });
  }

  static void _logFullPayload(Map<String, dynamic> payload, String source) {
    log("""
📋 Notification Paylog ($source)
--------------------------------
Type: ${payload['type'] ?? 'N/A'}
Full Payload:
${const JsonEncoder.withIndent('  ').convert(payload)}
--------------------------------
""");
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    log("""
📨 Showing Notification
----------------------
Title: $title
Body: $body
Payload: $payload
----------------------
""");
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  static void _handleMessage(RemoteMessage message) {
    log("🔄 Handling notification message");
    _logFullPayload(message.data, "Handling");

    if (navigatorKey.currentContext == null) {
      log("⚠️ No navigatorKey context available");
      return;
    }

    final data = message.data;

    // Handle call notifications
    if (data['type'] == 'incoming_call') {
      log("📞 Handling incoming call notification");
      _handleIncomingCallNotification(data);
      return;
    }

    // Handle chat notifications
    log("💬 Handling chat notification");
    final senderName = data['username'] ?? "Unknown";
    final profilePicId = int.tryParse(data['avatar_id'] ?? "0") ?? 0;
    final userId = int.tryParse(data['sender_id'] ?? "0") ?? 0;

    log("""
💬 Chat Notification Details:
- Sender: $senderName
- User ID: $userId
- Avatar ID: $profilePicId
""");

    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          avatarWidget: buildUserAvatar(profilePicId),
          userName: senderName,
          userId: userId,
          profilePicId: profilePicId,
        ),
      ),
      (route) => false,
    );

    initialNotificationPayload = null;
  }

  static void _handleIncomingCallNotification(Map<String, dynamic> data) {
  log("📞 Processing incoming call notification");

  try {
    final cubit = navigatorKey.currentContext?.read<CallSocketHandleCubit>();
    if (cubit == null) {
      log("⚠️ Call cubit not available in context");
      return;
    }

    if (cubit.isLiveCallActive) {
      log("⚠️ Call already active - ignoring duplicate notification");
      return;
    }

    // Safely parse caller ID with fallback to 0
    final callerId = int.tryParse(data['caller_id']?.toString() ?? "0") ?? 0;
    final callerName = data['caller_username']?.toString() ?? "Unknown";

    log("""
📞 Incoming Call Details:
- Caller ID: $callerId
- Caller Name: $callerName
- Current User ID: ${navigatorKey.currentContext?.read<UserProvider>().userId}
""");

    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => CallAcceptScreen(
          callerName: callerName,
          avatarUrl: 0,
          callerId: callerId,
        ),
      ),
      (route) => false,
    );
  } catch (e) {
    log("⚠️ Error handling incoming call notification: $e");
  }
}
}

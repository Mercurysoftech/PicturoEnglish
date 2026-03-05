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
import 'navigation_service.dart';

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
      rethrow;
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

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data =
                jsonDecode(response.payload ?? '{}');
            log("🔔 Notification tapped: $data");

            Future.delayed(const Duration(milliseconds: 500), () {
              Get.to(() => ChatScreen(
                    avatarWidget: buildUserAvatar(
                        data['sender_profile'] == "null"
                            ? 0
                            : int.parse(data['sender_profile'] ?? '0')),
                    userName:
                        data['username'] ?? (data['sender_username'] ?? 'N/A'),
                    userId: int.parse(data['sender_id'] ?? '0'),
                    profilePicId: data['sender_profile'] == "null"
                        ? 0
                        : int.parse(data['sender_profile'] ?? '0'),
                  ));
            });
            await flutterLocalNotificationsPlugin.cancel(response.id ?? 0);
          } catch (e) {
            log("⚠️ Error navigating from notification: $e");
          }
        }
      },
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        log("📱 App opened from terminated state with notification");
        _logFullPayload(message.data, "Terminated");
        _handleMessage(message);
      }
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

  static void showNotification(RemoteMessage message) {
    // Don't show normal notification for incoming calls - only CallKit
    if (message.data['type'] == 'incoming_call' ||
        (message.notification?.title?.toLowerCase().contains('incoming call') ??
            false)) {
      log("📞 Skipping normal notification for incoming_call - using CallKit instead");
      return;
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        payload: jsonEncode({
          "sender_id": "${message.data['sender_id']}",
          "username": "${message.data['username']}"
        }),
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
  }

  static void _handleMessage(RemoteMessage message) {
    log("🔄 Handling notification message");
    _logFullPayload(message.data, "Handling");

    if (NavigationService.instance.navigationKey.currentContext == null) {
      log("⚠️ No navigatorKey context available");
      return;
    }

    final data = message.data;

    // if (data['type'] == 'incoming_call') {
    //   log("📞 Handling incoming call notification");
    //   _handleIncomingCallNotification(data);
    //   return;
    // }

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

    if (data['type'] == 'chat') {
      Navigator.of(NavigationService.instance.navigationKey.currentContext!)
          .pushAndRemoveUntil(
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
    }

    initialNotificationPayload = null;
  }

  static void _handleIncomingCallNotification(Map<String, dynamic> data) {
    log("📞 Processing incoming call notification");

    try {
      final cubit = NavigationService.instance.navigationKey.currentContext
          ?.read<CallSocketHandleCubit>();
      if (cubit == null) {
        log("⚠️ Call cubit not available in context");
        return;
      }

      if (cubit.isLiveCallActive) {
        log("⚠️ Call already active - ignoring duplicate notification");
        return;
      }

      final callerId = int.tryParse(data['caller_id']?.toString() ?? "0") ?? 0;
      final callerName = data['caller_username']?.toString() ?? "Unknown";

      log("""
📞 Incoming Call Details:
- Caller ID: $callerId
- Caller Name: $callerName
- Current User ID: ${NavigationService.instance.navigationKey.currentContext?.read<UserProvider>().userId}
""");

      Navigator.of(NavigationService.instance.navigationKey.currentContext!)
          .pushAndRemoveUntil(
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

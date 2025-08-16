
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../main.dart';
import '../screens/chatscreenpage.dart';
import 'api_service.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();


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

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async{

        Map<String,dynamic> data=jsonDecode(response.payload??'');
        Future.delayed(Duration(milliseconds: 500), () {
          Get.to(()=>ChatScreen(
            avatarWidget: buildUserAvatar((data['sender_profile'].toString()==" null")?0:
            int.parse(data['sender_profile'].toString().split(' ')[1].toString())),
            userName:data['sender_Name'],
            userId: int.parse(data['sender_Id']),
            profilePicId: (data['sender_profile'].toString()==" null")?0:int.parse(data['sender_profile'].toString().split(' ')[1].toString()),
          )
          );

        });
        await flutterLocalNotificationsPlugin.cancel(response.id ?? 0);


      }
    );

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("📲 Foreground message ___ : ${message.toMap()} __ ");
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        if(notification.title=="Incoming Call"|| (notification.body.toString().contains('calling')??false)){
          showFlutterCallNotification(
            callSessionId: 'sdkjcslkcmslkcmsdc',
            userId: '${message.data['caller_id']}',
            callerName: '${message.data['caller_username']}',
          );
        }else{
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body?.split("-")[0],
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'channel_id',
                'channel_name',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            payload:jsonEncode({
              "sender_Id":message.data['sender_id'],
              "sender_Name": notification.body?.split("-")[1],
              "sender_profile": notification.body?.split("-")[2],
            }), // use message.data if you want to navigate
          );
        }

      }
    });

    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {

    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message);
    });


  }
  static void _handleMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    BuildContext? context = navigatorKey.currentContext;

    if (notification != null && context != null) {
      final body = notification.body ?? "";
      final senderName = body.split("-")[1];
      final profilePicPart = body.split("-")[2];
      final profilePicId = int.parse(profilePicPart.split(" ")[1]);

      final userId = int.parse(message.data['sender_id'] ?? '0');

      // Delay helps if navigation happens too early during cold start
      Future.delayed(Duration(milliseconds: 500), () {
        Get.to(() => ChatScreen(
              avatarWidget: buildUserAvatar(profilePicId),
              userName: senderName,
              userId: userId,
              profilePicId: profilePicId,
            ),
        );
      });
    }
  }
}
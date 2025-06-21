
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Triggered when the user taps on the notification
        if (response.payload != null) {
          Navigator.pushNamed(context, '/targetPage', arguments: response.payload);
        }
      },
    );

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📲 Foreground message ___ : ${message.toMap()}");
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['route'], // use message.data if you want to navigate
        );
      }
    });

    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print("lsdkcmslkdcmsldc ${message?.toMap()}");
      if (message != null) {
        Navigator.pushNamed(context, '/targetPage', arguments: message.data['route']);
      }
    });

    // App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("lsdkcmslkdcmsldc Opened  ${message?.toMap()}");

      Navigator.pushNamed(context, '/targetPage', arguments: message.data['route']);
    });
  }
}
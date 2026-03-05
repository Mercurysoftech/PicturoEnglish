// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class UnifiedNotificationService {
//   static final UnifiedNotificationService _instance = 
//       UnifiedNotificationService._internal();
//   factory UnifiedNotificationService() => _instance;
//   UnifiedNotificationService._internal();

//   final FlutterLocalNotificationsPlugin _notifications = 
//       FlutterLocalNotificationsPlugin();
  
//   // Track shown notifications to prevent duplicates
//   final Set<String> _shownNotificationIds = {};

//   Future<void> initialize() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     await _notifications.initialize(initializationSettings);
//   }

//   Future<void> showNotification({
//     required String title,
//     required String body,
//     required String payload,
//     required String notificationId,
//   }) async {
//     // Prevent duplicate notifications
//     if (_shownNotificationIds.contains(notificationId)) {
//       log('🔇 Skipping duplicate notification: $notificationId');
//       return;
//     }

//     // Validate data
//     if (title == 'null' || body == 'null' || title.isEmpty || body.isEmpty) {
//       log('⚠️ Skipping notification with invalid data');
//       return;
//     }

//     try {
//       await _notifications.show(
//         notificationId.hashCode,
//         title,
//         body,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'default_channel_id',
//             'Default Channel',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//         ),
//         payload: payload,
//       );

//       _shownNotificationIds.add(notificationId);
//       log('📢 Notification shown: $title');

//       // Clean up old IDs periodically
//       if (_shownNotificationIds.length > 100) {
//         _shownNotificationIds.clear();
//       }

//     } catch (e) {
//       log('❌ Failed to show notification: $e');
//     }
//   }

//   void clearShownIds() {
//     _shownNotificationIds.clear();
//   }
// }

// final unifiedNotificationService = UnifiedNotificationService();
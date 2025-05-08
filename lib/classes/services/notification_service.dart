import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // IDs for different notifications
  static const int morningNotificationId = 1;
  static const int eveningNotificationId = 2;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap if needed
      },
    );
    
    // Create notification channels
    await _createNotificationChannels();
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel morningChannel = AndroidNotificationChannel(
      'morning_picturo_channel',
      'Morning Reminders',
      description: 'Morning notification channel',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const AndroidNotificationChannel eveningChannel = AndroidNotificationChannel(
      'evening_picturo_channel',
      'Evening Reminders',
      description: 'Evening notification channel',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(morningChannel);

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eveningChannel);
  }

  Future<void> scheduleDailyNotifications({
    required TimeOfDay morningTime,
    required TimeOfDay eveningTime,
    required String morningTitle,
    required String morningBody,
    required String eveningTitle,
    required String eveningBody,
  }) async {
    // Check permissions first
    if (!await requestPermissions()) {
      throw Exception('Notification permissions not granted');
    }

    // Cancel any existing notifications first
    await cancelAllNotifications();

     final now = DateTime.now();
    print("Current time: $now");

    // 4. Schedule morning notification with logging
    final morningDateTime = _calculateScheduleTime(morningTime);
    print("Morning notification scheduled for: ${morningDateTime.toLocal()}");

    // Schedule morning notification
    await _scheduleSingleNotification(
      time: morningTime,
      title: morningTitle,
      body: morningBody,
      id: morningNotificationId,
      channelId: 'morning_picturo_channel',
    );

    // Schedule evening notification
    await _scheduleSingleNotification(
      time: eveningTime,
      title: eveningTitle,
      body: eveningBody,
      id: eveningNotificationId,
      channelId: 'evening_picturo_channel',
    );
  }
  DateTime _calculateScheduleTime(TimeOfDay time) {
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

  Future<void> _scheduleSingleNotification({
    required TimeOfDay time,
    required String title,
    required String body,
    required int id,
    required String channelId,
  }) async {
    final now = DateTime.now();
    var scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzScheduledDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId.contains('morning') ? 'Morning Reminders' : 'Evening Reminders',
      channelDescription: channelId.contains('morning')
          ? 'Morning notification channel'
          : 'Evening notification channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDateTime,
      NotificationDetails(android: androidDetails),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
     if (!await requestPermissions()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'picturo_channel',
      'Picturo Notifications',
      channelDescription: 'Notifications for Picturo App',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    await notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}
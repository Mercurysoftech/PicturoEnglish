import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForegroundService {
  static final ForegroundService _instance = ForegroundService._internal();
  factory ForegroundService() => _instance;
  ForegroundService._internal();

  static const String _channelId = "picturo_call_channel";
  static const String _channelName = "Ongoing Call";
  
  bool _isServiceRunning = false;
  Timer? _durationUpdateTimer;
  String _currentCallerName = 'Unknown';
  String _currentDuration = '00:00:00';
  bool _isMuted = false;

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Ongoing call notifications',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('ic_bg_service_small'),
        ),
      );
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Picturo - Call',
        initialNotificationContent: 'Call in progress',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startForegroundService({
    required String callerName,
    required String callDuration,
    required bool isVideoCall,
  }) async {
    if (_isServiceRunning) return;

    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();

    // Save call data for service restoration
    await prefs.setString('ongoing_call_caller', callerName);
    await prefs.setBool('ongoing_call_active', true);
    await prefs.setBool('ongoing_call_is_video', isVideoCall);
    await prefs.setString('call_start_time', DateTime.now().toIso8601String());

    _currentCallerName = callerName;
    _currentDuration = callDuration;

    // Start the service
    await service.startService();

    _isServiceRunning = true;
    
    // Start timer to update duration
    _startDurationUpdateTimer();
  }

  Future<void> updateCallDuration(String duration) async {
    if (!_isServiceRunning) return;

    _currentDuration = duration;
    
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('updateCallNotification', {
        'callerName': _currentCallerName,
        'callDuration': duration,
        'isMuted': _isMuted,
      });
    }
  }

  Future<void> toggleMute(bool isMuted) async {
    _isMuted = isMuted;
    
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('updateCallNotification', {
        'callerName': _currentCallerName,
        'callDuration': _currentDuration,
        'isMuted': isMuted,
      });
    }
  }

  Future<void> stopForegroundService() async {
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = null;

    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('ongoing_call_caller');
    await prefs.remove('ongoing_call_active');
    await prefs.remove('ongoing_call_is_video');
    await prefs.remove('call_start_time');

    if (await service.isRunning()) {
      service.invoke('stopService');
    }

    _isServiceRunning = false;
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  Future<Map<String, dynamic>?> getOngoingCallData() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isActive = prefs.getBool('ongoing_call_active') ?? false;
    
    if (!isActive) return null;

    final startTimeStr = prefs.getString('call_start_time');
    final startTime = startTimeStr != null ? DateTime.parse(startTimeStr) : DateTime.now();
    final duration = DateTime.now().difference(startTime);

    return {
      'callerName': prefs.getString('ongoing_call_caller') ?? 'Unknown',
      'isVideoCall': prefs.getBool('ongoing_call_is_video') ?? false,
      'isActive': true,
      'startTime': startTime,
      'duration': duration,
    };
  }

  void _startDurationUpdateTimer() {
    _durationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final ongoingCall = await getOngoingCallData();
      if (ongoingCall != null && ongoingCall['isActive']) {
        final duration = ongoingCall['duration'] as Duration;
        final formattedDuration = _formatDuration(duration);
        await updateCallDuration(formattedDuration);
      } else {
        timer.cancel();
        await stopForegroundService();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Stream<Map<String, dynamic>?> get onServiceUpdate {
    return FlutterBackgroundService().on('callUpdate');
  }

  void dispose() {
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = null;
  }
}

// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  
  final log = preferences.getStringList('call_log') ?? <String>[];
  log.add('iOS Background: ${DateTime.now().toIso8601String()}');
  await preferences.setStringList('call_log', log);

  return true;
}

// Main service handler
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });


  service.on('updateCallNotification').listen((event) async {
    final callerName = event?['callerName'] ?? 'Unknown';
    final callDuration = event?['callDuration'] ?? '00:00:00';
    final isMuted = event?['isMuted'] ?? false;

    final muteText = isMuted ? ' (Muted)' : '';
    
    // Update notification using flutter_local_notifications
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.show(
        888,
        'Picturo - Call with $callerName',
        'Duration: $callDuration$muteText',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'picturo_call_channel',
            'Ongoing Call',
            channelDescription: 'Ongoing call notifications',
            icon: 'ic_bg_service_small',
            ongoing: true,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: false,
            actions: [
              // AndroidNotificationAction(
              //   'mute_action',
              //   'Mute',
              // ),
              AndroidNotificationAction(
                'end_call_action',
                'End Call',
              ),
            ],
          ),
        ),
      );
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin.show(
        888,
        'Picturo - Call with $callerName',
        'Duration: $callDuration$muteText',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
        ),
      );
    }

    // Send update to UI
    service.invoke('callUpdate', {
      'callerName': callerName,
      'duration': callDuration,
      'isMuted': isMuted,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // Handle mute/unmute actions
  service.on('toggleMute').listen((event) {
    final isMuted = event?['isMuted'] ?? false;
    service.invoke('callUpdate', {
      'action': 'muteToggled',
      'isMuted': isMuted,
    });
  });

  // Keep the service alive and update periodically
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Check if call is still active
        final prefs = await SharedPreferences.getInstance();
        final bool isCallActive = prefs.getBool('ongoing_call_active') ?? false;
        
        if (!isCallActive) {
          timer.cancel();
          service.stopSelf();
          return;
        }

        // Send heartbeat to keep service alive
        service.invoke('callUpdate', {
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }

    // iOS background handling
    if (Platform.isIOS) {
      final prefs = await SharedPreferences.getInstance();
      final log = prefs.getStringList('call_log') ?? <String>[];
      log.add('Service heartbeat: ${DateTime.now().toIso8601String()}');
      await prefs.setStringList('call_log', log);
    }
  });
}

// Simple widget to listen for service updates
class CallServiceListener extends StatefulWidget {
  final Widget child;
  final void Function(Map<String, dynamic>?) onCallUpdate;

  const CallServiceListener({
    super.key,
    required this.child,
    required this.onCallUpdate,
  });

  @override
  State<CallServiceListener> createState() => _CallServiceListenerState();
}

class _CallServiceListenerState extends State<CallServiceListener> {
  final ForegroundService _service = ForegroundService();
  StreamSubscription<Map<String, dynamic>?>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _updateSubscription = _service.onServiceUpdate.listen(widget.onCallUpdate);
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Utility to handle notification actions
class NotificationActionHandler {
  static void handleNotificationAction(String actionId) {
    final service = FlutterBackgroundService();
    
    switch (actionId) {
      case 'mute_action':
        service.invoke('toggleMute', {'isMuted': true});
        break;
      case 'end_call_action':
        service.invoke('stopService');
        break;
    }
  }
}
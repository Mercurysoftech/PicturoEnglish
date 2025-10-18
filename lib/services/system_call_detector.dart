// system_call_detector.dart
import 'package:flutter/services.dart';

class SystemCallDetector {
  static const MethodChannel _channel = MethodChannel('system_call_detector');
  
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initializeSystemCallDetection');
    } on PlatformException catch (e) {
      print("Failed to initialize system call detection: '${e.message}'");
    }
  }
  
  static Stream<String> get systemCallStream {
    return const EventChannel('system_call_events')
        .receiveBroadcastStream()
        .map((event) => event.toString());
  }
}
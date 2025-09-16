import 'package:flutter/services.dart';

class CallServiceController {
  static const MethodChannel _channel = MethodChannel('picturo_call');

  static Future<void> start(String callId) async {
    await _channel.invokeMethod('startCallService', {'callId': callId});
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopCallService');
  }
}

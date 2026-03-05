import 'dart:developer';
import 'package:flutter/services.dart';

class NativeChannelHelper {
  static const MethodChannel _channel =
      MethodChannel('picturo_call_service');

  static Future<void> invoke(String method, [dynamic arguments]) async {
    try {
      await _channel.invokeMethod(method, arguments);
    } on MissingPluginException {
      log("⚠️ Native method not implemented: $method");
    } catch (e) {
      log("❌ Native channel error ($method): $e");
    }
  }

  static Future<dynamic> invokeWithResult(String method,
      [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod(method, arguments);
    } on MissingPluginException {
      log("⚠️ Native method not implemented: $method");
      return null;
    } catch (e) {
      log("❌ Native channel error ($method): $e");
      return null;
    }
  }
}

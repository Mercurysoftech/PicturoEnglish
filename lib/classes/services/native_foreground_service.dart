import 'package:flutter/services.dart';

class NativeForegroundService {
  static const MethodChannel _channel = MethodChannel('picturo_call_service');

  Future<void> startCallService({
    required String callerName,
    required String targetUserId,
    bool isVideoCall = false,
  }) async {
    try {
      await _channel.invokeMethod('startCallService', {
        'callerName': callerName,
        'targetUserId': targetUserId,
        'isVideoCall': isVideoCall,
      });
    } catch (e) {
      print('Error starting call service: $e');
    }
  }

  Future<void> stopCallService() async {
    try {
      await _channel.invokeMethod('stopCallService');
    } catch (e) {
      print('Error stopping call service: $e');
    }
  }

  Future<void> callConnected() async {
    try {
      await _channel.invokeMethod('callConnected');
    } catch (e) {
      print('Error notifying call connected: $e');
    }
  }

  Future<void> callDisconnected() async {
    try {
      await _channel.invokeMethod('callDisconnected');
    } catch (e) {
      print('Error notifying call disconnected: $e');
    }
  }

  Future<void> toggleCallMute(bool isMuted) async {
    try {
      await _channel.invokeMethod('toggleCallMute', {
        'isMuted': isMuted,
      });
    } catch (e) {
      print('Error toggling call mute: $e');
    }
  }

  Future<void> updateCallDuration(String duration) async {
    try {
      await _channel.invokeMethod('updateCallDuration', {
        'duration': duration,
      });
    } catch (e) {
      print('Error updating call duration: $e');
    }
  }

  Future<bool> isCallServiceRunning() async {
    try {
      final bool isRunning =
          await _channel.invokeMethod('isCallServiceRunning');
      return isRunning;
    } catch (e) {
      print('Error checking service status: $e');
      return false;
    }
  }
}

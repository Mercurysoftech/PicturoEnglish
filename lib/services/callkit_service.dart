import 'dart:developer';
import 'dart:io';

import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:picturo_app/classes/callkit_session.dart';

class CallKitService {
  /// SHOW INCOMING CALL (ANDROID ONLY)
  static Future<void> showIncoming({
    required String callerName,
    required String userId,
    required int callerId,
    required int receiverId,
  }) async {
    // 🚫 iOS MUST NOT use flutter_callkit_incoming
    if (Platform.isIOS) {
      log("🚫 iOS incoming call handled by native CallKit");
      return;
    }

    final uuid = CallKitSession.start();

    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Picturo',
      handle: 'Call from $callerName',
      type: 0,
      duration: 30000,
      extra: {
        'userId': userId,
        'callerId': callerId.toString(),
        'receiverId': receiverId.toString(),
      },
      ios: const IOSParams(
        supportsVideo: false,
        audioSessionActive: true,
        audioSessionMode: 'default',
      ),
      android: const AndroidParams(
        isImportant: true,
        isShowFullLockedScreen: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// MARK CALL CONNECTED (ANDROID ONLY)
  static Future<void> setConnected() async {
    if (Platform.isIOS) return;

    if (!CallKitSession.hasActive) return;

    try {
      await FlutterCallkitIncoming.setCallConnected(
        CallKitSession.uuid!,
      );
    } catch (e) {
      log("❌ setCallConnected error: $e");
    }
  }

  /// END CALL SAFELY (ANDROID ONLY)
  static Future<void> end() async {
    if (Platform.isIOS) {
      log("🚫 iOS call end handled natively");
      return;
    }

    if (!CallKitSession.hasActive) {
      log("⚠️ No active CallKit session");
      return;
    }

    try {
      await FlutterCallkitIncoming.endCall(
        CallKitSession.uuid!,
      );
    } catch (e) {
      log("❌ endCall error: $e");
    } finally {
      CallKitSession.clear();
    }
  }

  /// FORCE CLEANUP (ANDROID ONLY)
  static Future<void> endAll() async {
    if (Platform.isIOS) {
      CallKitSession.clear();
      return;
    }

    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}

    CallKitSession.clear();
  }
}

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:picturo_app/classes/helper/call_info_storage_helper.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/navigation_service.dart';

class AndroidCallKitListener {
  static bool _initialized = false;

  static void initialize() {
    // 🔒 Prevent duplicate listeners
    if (_initialized) return;
    _initialized = true;

    // ❌ Never run on iOS — iOS uses AppDelegate.swift MethodChannel
    if (Platform.isIOS) return;

    FlutterCallkitIncoming.onEvent.listen((event) async {
      log("📞 [Android] CallKit event received: ${event?.event}");

      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          await _onCallAccepted(event);
          break;

        case Event.actionCallDecline:
          _onCallDeclined();
          break;

        case Event.actionCallEnded:
          // CallKit fires actionCallEnded when the notification is dismissed
          // (after auto-timeout or user swipe without answering).
          // NEVER end an active call from this event — active calls are only
          // ended via the in-app end button or socket call-ended events.
          _onCallEnded();
          break;

        default:
          break;
      }
    });
  }

  static Future<void> _onCallAccepted(CallEvent event) async {
    final data = event.body ?? {};
    final target =
        int.tryParse(data["extra"]?['userId']?.toString() ?? "0") ?? 0;
    final callerName = data['nameCaller']?.toString() ?? "Unknown";
    final callerImage = data["extra"]?['avatar']?.toString() ?? "0";

    log("✅ [Android] Call accepted: $callerName ($target)");

    // Capture context-dependent objects BEFORE the async gap
    final contextBefore =
        NavigationService.instance.navigationKey.currentContext;
    if (contextBefore == null) return;
    final cubit = contextBefore.read<CallSocketHandleCubit>();

    // Async operation
    await CallInfoStorage.saveCallInfo(
      callerId: target,
      callerName: callerName,
      isIncoming: false,
    );

    // After async gap: use NavigatorState directly — avoids BuildContext across await
    final navigatorState = NavigationService.instance.navigationKey.currentState;
    if (navigatorState == null) return;

    if (cubit.isLiveCallActive) {
      log("⚠️ [Android] Call already active — ignoring duplicate accept");
      return;
    }

    cubit.targetUserId = target;
    cubit.callerName = callerName;

    navigatorState.push(
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          callerId: target,
          callerName: callerName,
          callerImage: callerImage,
          isIncoming: false,
        ),
      ),
    );
  }

  static void _onCallDeclined() {
    log("❌ [Android] Call declined via CallKit");

    final context = NavigationService.instance.navigationKey.currentContext;
    if (context == null) return;

    context.read<CallSocketHandleCubit>().endCall();
  }

  static void _onCallEnded() {
    // Only clean up if no active call exists — prevents ending a live call
    final context = NavigationService.instance.navigationKey.currentContext;
    if (context == null) return;

    final cubit = context.read<CallSocketHandleCubit>();
    if (!cubit.isLiveCallActive) {
      log("📞 [Android] CallKit notification dismissed (no active call) — cleaning up");
      cubit.endCall();
    } else {
      log("📞 [Android] actionCallEnded ignored (active call managed by app/socket)");
    }
  }
}

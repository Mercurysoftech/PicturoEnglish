// Complete native_call_listener.dart with microphone permission handling

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picturo_app/services/navigation_service.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/classes/helper/call_info_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NativeCallListener {
  static const MethodChannel _channel = MethodChannel('picturo_call_service');
  static bool _isProcessingAccept = false;
  static DateTime? _lastAcceptTime;

  static void initialize() {
    log("📱 ========================================");
    log("📱 Initializing NativeCallListener");
    log("📱 ========================================");

    _channel.setMethodCallHandler((call) async {
      log("📱 ========================================");
      log("📱 NATIVE METHOD CALL: ${call.method}");
      log("📱 Arguments: ${call.arguments}");
      log("📱 Timestamp: ${DateTime.now()}");
      log("📱 ========================================");

      switch (call.method) {
        case 'onCallAccepted':
          await _handleCallAccepted(call.arguments);
          break;

        case 'onCallDeclined':
          await _handleCallDeclined(call.arguments);
          break;

        case 'onCallEnded':
          await _handleCallEnded(call.arguments);
          break;

        case 'onVoIPToken':
          await _handleVoIPToken(call.arguments);
          break;
      }
    });

    log("✅ NativeCallListener initialized");
  }

  static Future<void> _handleCallAccepted(dynamic arguments) async {
    if (_isProcessingAccept) {
      log("⚠️ Already processing call accept, ignoring duplicate");
      return;
    }

    if (_lastAcceptTime != null) {
      final timeSinceLastAccept = DateTime.now().difference(_lastAcceptTime!);
      if (timeSinceLastAccept.inSeconds < 2) {
        log("⚠️ Call accept too soon (${timeSinceLastAccept.inSeconds}s), ignoring");
        return;
      }
    }

    _isProcessingAccept = true;
    _lastAcceptTime = DateTime.now();

    try {
      final data = Map<String, dynamic>.from(arguments);
      final callerId = int.tryParse(data['caller_id']?.toString() ?? "0") ?? 0;
      final callerName = data['caller_username']?.toString() ?? "Unknown";

      log("📞 ========================================");
      log("📞 INCOMING CALL ACCEPTED FROM CALLKIT");
      log("📞 Caller: $callerName (ID: $callerId)");
      log("📞 ========================================");

      if (callerId == 0) {
        log("❌ Invalid caller ID");
        _isProcessingAccept = false;
        return;
      }

      // ⭐ CRITICAL FIX #1: Notify iOS IMMEDIATELY that call is accepted
      // This must happen BEFORE any async work (mic permission, WebRTC setup)
      // This prevents Swift from treating premature ends as declines
      try {
        await _channel.invokeMethod('callConnected');
        log("✅ iOS notified: Call is active (IMMEDIATE - before async work)");
      } catch (e) {
        log("⚠️ Failed to notify iOS immediately: $e");
      }

      final context = NavigationService.instance.navigationKey.currentContext;
      final isAppInForeground = context != null;

      // ⭐ REQUEST MICROPHONE PERMISSION
      log("🎤 ========================================");
      log("🎤 REQUESTING MICROPHONE PERMISSION");
      log("🎤 App in foreground: $isAppInForeground");
      log("🎤 ========================================");

      bool hasPermission = false;

      // Show loading dialog if app is visible
      if (isAppInForeground && context!.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Setting up call...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please grant microphone permission',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      try {
        // Request microphone via WebRTC
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
          },
          'video': false,
        }).timeout(
          Duration(seconds: 10),
          onTimeout: () {
            log("⏰ Microphone request timed out");
            throw TimeoutException('Microphone permission timeout');
          },
        );

        final audioTracks = stream.getAudioTracks();

        if (audioTracks.isEmpty) {
          log("❌ No audio tracks available");
          hasPermission = false;
        } else {
          log("✅ Microphone granted (${audioTracks.length} tracks)");
          hasPermission = true;
        }

        // Clean up test stream
        for (var track in stream.getTracks()) {
          track.stop();
        }
        await stream.dispose();
      } catch (e) {
        log("❌ Microphone permission error: $e");
        hasPermission = false;
      }

      // Dismiss loading dialog
      if (isAppInForeground && context != null && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      // ⭐ HANDLE PERMISSION DENIAL
      if (!hasPermission) {
        log("❌ ========================================");
        log("❌ MICROPHONE PERMISSION DENIED");
        log("❌ Ending call");
        log("❌ ========================================");

        // Show error dialog if visible
        if (isAppInForeground && context != null && context.mounted) {
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.mic_off, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(child: Text('Microphone Required')),
                ],
              ),
              content: Text(
                'Microphone access is required to answer calls. Please enable it in Settings to receive calls.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('OK'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await openAppSettings();
                  },
                  child: Text('Settings'),
                ),
              ],
            ),
          );
        }

        // End CallKit session
        await endCall();

        // Reject on server
        try {
          final apiService = await ApiService.create();
          final prefs = await SharedPreferences.getInstance();
          final receiverId =
              int.tryParse(prefs.getString('user_id') ?? "0") ?? 0;

          if (receiverId != 0) {
            await apiService.rejectCall(callerId, receiverId);
            log("✅ Call rejected on server (no mic permission)");
          }
        } catch (e) {
          log("⚠️ Failed to reject on server: $e");
        }

        _isProcessingAccept = false;
        return;
      }

      log("✅ ========================================");
      log("✅ MICROPHONE PERMISSION GRANTED");
      log("✅ Proceeding with call");
      log("✅ ========================================");

      // ⭐ NEW: End CallKit BEFORE accepting call via cubit
      if (Platform.isIOS) {
        try {
          await _channel.invokeMethod('endCall');
          log("✅ CallKit ended BEFORE WebRTC setup");
          
          // Wait for CallKit to fully release audio session
          await Future.delayed(Duration(milliseconds: 300));
        } catch (e) {
          log("⚠️ Error ending CallKit early: $e");
        }
      }

      // Save call info
      await CallInfoStorage.saveCallInfo(
        callerId: callerId,
        callerName: callerName,
        isIncoming: true,
      );

      if (context == null || !context.mounted) {
        log("❌ No valid context");
        _isProcessingAccept = false;
        return;
      }

      final cubit = context.read<CallSocketHandleCubit>();

      if (cubit.isLiveCallActive) {
        log("⚠️ Already in call");
        _isProcessingAccept = false;
        return;
      }

      cubit.targetUserId = callerId;
      cubit.callerName = callerName;

      log("📞 Accepting call via cubit");
      cubit.acceptCall(callerId, callerName: callerName);

      // ⭐ CRITICAL FIX #4: Wait for call to actually be active before navigation
      log("📞 Waiting for call to become active...");

      int waitAttempts = 0;
      const maxWaitAttempts = 50; // 5 seconds max

      while (waitAttempts < maxWaitAttempts) {
        await Future.delayed(Duration(milliseconds: 100));

        if (cubit.isLiveCallActive) {
          // Also check if WebRTC peer connection exists and has tracks
          final pc = cubit.peerConnections[callerId.toString()];
          if (pc != null) {
            try {
              final senders = await pc.getSenders();
              final hasAudioTrack = senders.any((sender) =>
                  sender.track != null && sender.track!.kind == 'audio');

              if (hasAudioTrack) {
                log("✅ Call is active and WebRTC has audio track");
                break;
              }
            } catch (e) {
              log("⚠️ Error checking senders: $e");
            }
          }

          // If we have isLiveCallActive but no tracks yet, continue waiting
          if (waitAttempts % 10 == 0) {
            log("⏳ Call active but WebRTC tracks not ready yet... (${waitAttempts * 100}ms)");
          }
        }

        waitAttempts++;

        if (waitAttempts >= maxWaitAttempts) {
          log("⚠️ Timeout waiting for call to become active");
          // Continue anyway - call might still work
          break;
        }
      }

      if (!cubit.isLiveCallActive) {
        log("❌ Call did not become active, aborting navigation");
        await endCall();
        _isProcessingAccept = false;
        return;
      }

      log("📞 Navigating to VoiceCallScreen");

      if (context.mounted) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              callerId: callerId,
              callerName: callerName,
              callerImage: '',
              isIncoming: true,
            ),
          ),
          (route) => false,
        );

        log("✅ Navigation complete");
      }
    } catch (e, stackTrace) {
      log("❌ Error: $e");
      log("Stack: $stackTrace");

      // Clean up
      final context = NavigationService.instance.navigationKey.currentContext;
      if (context != null && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      await endCall();
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _isProcessingAccept = false;
      });
    }
  }

  static Future<void> _handleCallDeclined(dynamic arguments) async {
    log("❌ ========================================");
    log("❌ CALL DECLINED VIA CALLKIT");
    log("❌ Timestamp: ${DateTime.now()}");
    log("❌ ========================================");

    // ⭐ CRITICAL FIX: Ignore premature decline events
    // If we just accepted a call within the last 20 seconds, ignore this decline
    if (_lastAcceptTime != null) {
      final timeSinceAccept = DateTime.now().difference(_lastAcceptTime!);
      if (timeSinceAccept.inSeconds < 20) {
        log("⚠️ ========================================");
        log("⚠️ IGNORING PREMATURE CALL DECLINE");
        log("⚠️ Call was accepted ${timeSinceAccept.inSeconds}s ago");
        log("⚠️ Threshold: 20 seconds");
        log("⚠️ This is likely a race condition, not a real decline");
        log("⚠️ ========================================");
        return; // Don't process this decline
      }
    }

    // Also check if call is actually active - if so, ignore decline
    final checkContext =
        NavigationService.instance.navigationKey.currentContext;
    if (checkContext != null) {
      try {
        final cubit = checkContext.read<CallSocketHandleCubit>();
        if (cubit.isLiveCallActive) {
          log("⚠️ ========================================");
          log("⚠️ IGNORING CALL DECLINE - CALL IS ACTIVE");
          log("⚠️ Call is live and active (isLiveCallActive: ${cubit.isLiveCallActive})");
          log("⚠️ This decline is stale/incorrect");
          log("⚠️ ========================================");
          return; // Don't process if call is actually active
        }
      } catch (e) {
        log("⚠️ Error checking call state: $e");
      }
    }

    final data = Map<String, dynamic>.from(arguments);
    final callerId = int.tryParse(data['caller_id']?.toString() ?? "0") ?? 0;
    final receiverId =
        int.tryParse(data['receiver_id']?.toString() ?? "0") ?? 0;

    log("❌ Caller ID: $callerId");
    log("❌ Receiver ID: $receiverId");

    if (callerId == 0 || receiverId == 0) {
      log("❌ Invalid IDs - cannot reject call");
      _isProcessingAccept = false;
      _lastAcceptTime = null;
      return;
    }

    // ⭐ STEP 1: End CallKit session immediately
    try {
      await endCall();
      log("✅ CallKit session ended");
    } catch (e) {
      log("⚠️ Error ending CallKit: $e");
    }

    // ⭐ STEP 2: Notify server via API
    try {
      log("📡 Calling reject API...");
      final apiService = await ApiService.create();
      final result = await apiService.rejectCall(callerId, receiverId);

      if (result['status'] == true) {
        log("✅ Call rejection API successful: ${result['message']}");
      } else {
        log("⚠️ Call rejection API failed: ${result['message']}");
      }
    } catch (e) {
      log("❌ Error calling reject API: $e");
    }

    // ⭐ STEP 3: End call via cubit (which emits to socket)
    final context = NavigationService.instance.navigationKey.currentContext;
    if (context != null) {
      try {
        final cubit = context.read<CallSocketHandleCubit>();

        log("📡 Emitting call-rejected to socket...");

        // Emit rejection to socket BEFORE ending call locally
        cubit.callSocket?.emit('call-rejected', {
          'from': receiverId,
          'to': callerId,
        });

        log("✅ Socket emit sent");

        // Small delay to ensure socket message is sent
        await Future.delayed(const Duration(milliseconds: 300));

        // Now end the call locally
        await cubit.endCall();
        log("✅ Local call ended via cubit");
      } catch (e) {
        log("❌ Error ending call via cubit: $e");
      }
    } else {
      log("⚠️ No context available for cubit");
    }

    _isProcessingAccept = false;
    _lastAcceptTime = null;

    log("❌ ========================================");
    log("❌ CALL DECLINE COMPLETE");
    log("❌ ========================================");
  }

  static Future<void> _handleCallEnded(dynamic arguments) async {
    log("📞 CALL ENDED");

    if (arguments is Map) {
      final data = Map<String, dynamic>.from(arguments);
      final duration = data['duration'] ?? 0;
      log("📞 Duration: ${duration}s");
    }

    final context = NavigationService.instance.navigationKey.currentContext;
    if (context != null) {
      final cubit = context.read<CallSocketHandleCubit>();
      if (cubit.isLiveCallActive) {
        await cubit.endCall();
      }
    }

    _isProcessingAccept = false;
    _lastAcceptTime = null;
  }

  static Future<void> _handleVoIPToken(dynamic arguments) async {
    final String? token = arguments is String
        ? arguments
        : arguments is Map
            ? arguments['token']
            : null;

    if (token == null || token.isEmpty) return;

    log("📱 VoIP Token: ${token.substring(0, 20)}...");

    try {
      await saveVoipTokenLocally(token);
      log("✅ Token saved");
    } catch (e) {
      log("❌ Error saving token: $e");
    }
  }

  static Future<void> saveVoipTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("voip_token", token);
  }

  static Future<void> endCall() async {
    try {
      await _channel.invokeMethod('endCall');
      log("✅ End call sent to iOS");
      _isProcessingAccept = false;
      _lastAcceptTime = null;
    } catch (e) {
      log("❌ Error ending call: $e");
    }
  }
}

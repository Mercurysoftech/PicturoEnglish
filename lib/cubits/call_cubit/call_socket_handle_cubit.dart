import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:phone_state/phone_state.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:picturo_app/classes/helper/call_info_storage_helper.dart';
import 'package:picturo_app/classes/services/native_foreground_service.dart';
import 'package:picturo_app/providers/remaining_minutes_provider.dart';
import 'package:picturo_app/services/applifecycleservice.dart';
import 'package:picturo_app/services/call_foreground_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import '../../responses/allusers_response.dart';
import '../../responses/friends_response.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';

part 'call_socket_handle_state.dart';

class CallSocketHandleCubit extends Cubit<CallSocketHandleState> {
  CallSocketHandleCubit() : super(CallSocketHandleInitial());

  late IO.Socket callSocket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool isLiveCallActive = false;
  bool isAnotherCall = false;

  List<Friends> friends = [];
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Map<String, RTCPeerConnection> peerConnections = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Set<String> _processingSignal = {};
  int? targetUserId;
  String? callerName;
  Timer? _callTimeoutTimer;
  DateTime? _callAcceptedTime;
  final int _callTimeoutSeconds = 30;

  RemainingMinutesProvider? _remainingMinutesProvider;
  bool _isSystemCallActive = false;
  StreamSubscription? _callKitEventListener;
  int remainingMinutesRequestCount = 0;

  //final ForegroundService _foregroundService = ForegroundService();
  final NativeForegroundService _foregroundService = NativeForegroundService();

  final _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': [
          'turn:server.srivelavantraders.com:3478?transport=udp',
          'turn:server.srivelavantraders.com:3478?transport=tcp',
          'turns:server.srivelavantraders.com:5349?transport=tcp'
        ],
        'username': 'demo',
        'credential': 'password@123'
      }
    ],
    'sdpSemantics': 'unified-plan',
    // 'iceTransportPolicy': 'all', // or 'relay' to force TURN for testing
  };

  // Future<void> rejectCallWithApi(int callerId) async {
  //   try {
  //     final apiService = await ApiService.create();
  //     final result = await apiService.rejectCall(callerId);

  //     if (result['status'] == true) {
  //       log("✅ Call rejection API call successful: ${result['message']}");
  //     } else {
  //       log("⚠️ Call rejection API call failed: ${result['message']}");
  //     }
  //   } catch (e) {
  //     log("❌ Error making reject call API: $e");
  //   }
  // }

  Future<void> _syncCallerInfoToStorage() async {
    if (targetUserId != null && callerName != null && callerName!.isNotEmpty) {
      await CallInfoStorage.saveCallInfo(
        callerId: targetUserId!,
        callerName: callerName!,
      );
    }
  }

  Future<void> _loadCallerInfoFromStorage() async {
    final callInfo = await CallInfoStorage.getCallInfo();
    if (callInfo != null) {
      targetUserId = callInfo['callerId'];
      callerName = callInfo['callerName'];
      log('✅ Loaded caller info from storage: $callerName (ID: $targetUserId)');
    }
  }

  Future<String> getCallerName() async {
    if (callerName != null &&
        callerName!.isNotEmpty &&
        callerName != 'Unknown') {
      return callerName!;
    }

    final callInfo = await CallInfoStorage.getCallInfo();
    if (callInfo != null) {
      final storedName = callInfo['callerName'];
      if (storedName != null && storedName.isNotEmpty) {
        callerName = storedName;
        return storedName;
      }
    }

    return 'Unknown';
  }

  Future<void> _notifyIOSCallConnected() async {
    if (!Platform.isIOS) return;
    try {
      const platform = MethodChannel('picturo_call_service');
      await platform.invokeMethod('callConnected');
      log("✅ iOS: Notified native that WebRTC call is connected");
    } catch (e) {
      log("⚠️ iOS: Error notifying call connected: $e");
    }
  }

  Future<void> prepareIOSMic() async {
    if (!Platform.isIOS) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      await session.setActive(true);
      log("✅ iOS: Audio session configured for VoIP");
    } catch (e) {
      log("⚠️ iOS: Error configuring audio session: $e");
    }
  }

  void setRemainingMinutesProvider(RemainingMinutesProvider provider) {
    _remainingMinutesProvider = provider;
  }

  void updateRemainingMinutes(int minutes) {
    emit(state.copyWith(remainingMinutes: minutes));
  }

  Future<void> _storeCallDataForService(
      int targetUserId, String callerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_call_target_id', targetUserId);
    await prefs.setString('last_caller_name', callerName);
    await prefs.setBool('has_active_call', true);
  }

  Future<Map<String, dynamic>?> _getStoredCallData() async {
    final prefs = await SharedPreferences.getInstance();
    final hasActiveCall = prefs.getBool('has_active_call') ?? false;
    if (hasActiveCall) {
      final targetUserId = prefs.getInt('last_call_target_id');
      final callerName = prefs.getString('last_caller_name');
      return {
        'targetUserId': targetUserId,
        'callerName': callerName,
      };
    }
    return null;
  }

  Future<void> _clearStoredCallData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_call_target_id');
    await prefs.remove('last_caller_name');
    await prefs.remove('has_active_call');
  }

  void toggleMute() {
    final currentState = state;
    final newMuteState = !currentState.isMuted;

    // Update the actual audio state
    _muteLocalAudio(newMuteState);

    // Emit socket event
    if (_isSocketInitialized) {
      callSocket.emit("mute-call", {"to": targetUserId, "muted": newMuteState});
    }

    // Update UI state
    emit(state.copyWith(isMuted: newMuteState));
  }

  void toggleSpeaker() async {
    final currentState = state;
    final newSpeakerState = !currentState.isSpeakerOn;

    // Update the actual speaker state
    await Helper.setSpeakerphoneOn(newSpeakerState);

    // Update UI state
    emit(state.copyWith(isSpeakerOn: newSpeakerState));
  }

  void userOpenCalling() {
    // userOpenCallingPage=true;
  }
  void userCloseCalling() {
    // userOpenCallingPage=false;
  }
  Future<void> fetchAllUsers() async {
    final apiService = await ApiService.create();
    final FriendsResponse friendsResponse = await apiService.fetchFriends();
    friends = friendsResponse.data;
    emit(state);
  }

  void updateFriendsList(List<Friends> friendsList) {
    friends = friendsList;
    emit(state);
  }

  void disposeScoket() {
    print('Call Socket Dispossed');
    if (_isSocketInitialized) {
      callSocket.dispose();
    }
  }

  String _ordinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  void requestRemainingMinutes() {
    remainingMinutesRequestCount++;

    if (!_isSocketInitialized) {
      log("⚠️ Socket not initialized, cannot request remaining minutes (attempt ${remainingMinutesRequestCount})");
      return;
    }

    if (callSocket.connected) {
      callSocket.emit("get-remaining-daily-minutes");
      log("📊 Requesting remaining minutes... for ${_ordinal(remainingMinutesRequestCount)} time");
    } else {
      log("⚠️ Socket not connected, cannot request remaining minutes (attempt ${remainingMinutesRequestCount})");
    }
  }

  /// Call this method after user upgrades their plan to instantly refresh
  /// the plan data from server and update remaining minutes
  void refreshPlan() {
    if (!_isSocketInitialized) {
      log("⚠️ Socket not initialized, cannot refresh plan");
      return;
    }
    if (callSocket.connected) {
      callSocket.emit("refresh-plan");
      log("🔄 Emitting refresh-plan event to server...");
    } else {
      log("⚠️ Socket not connected, cannot refresh plan");
      // Fallback: request remaining minutes instead
      requestRemainingMinutes();
    }
  }

  bool _isSocketInitialized = false;
  String? _connectedUserId;

  Future<void> initCallSocket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? userId = prefs.getString("user_id");

    // Don't initialize if no user is logged in
    if (userId == null || userId.isEmpty) {
      log("⚠️ No user_id found, skipping call socket initialization");
      return;
    }

    // Only skip re-initialization if there's an ACTIVE LIVE CALL for the SAME user.
    if (_isSocketInitialized &&
        callSocket.connected &&
        isLiveCallActive &&
        _connectedUserId == userId) {
      log("⚡ Call socket already connected with active call for user $userId, skipping re-initialization");
      return;
    }

    // If user changed, force disconnect even if call is active
    if (_isSocketInitialized &&
        _connectedUserId != null &&
        _connectedUserId != userId) {
      log("🔄 Call socket was for user $_connectedUserId but current user is $userId. Force reconnecting...");
    }

    // Disconnect existing socket if initialized but not connected or call ended
    if (_isSocketInitialized) {
      try {
        callSocket.disconnect();
        callSocket.dispose();
        log("🔌 Disconnected old call socket for re-initialization");
      } catch (e) {
        log("⚠️ Error disconnecting old socket: $e");
      }
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    await _loadCallerInfoFromStorage();

    //await _foregroundService.initializeService();

    callSocket = IO.io(
      'https://picturoenglish.com:7656',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 2000,
        'forceNew': true, // 🔥 Force new connection to update query params
        'query': {
          'userId': userId,
          'fcmToken': token,
        },
      },
    );

    callSocket.connect();
    _isSocketInitialized = true;
    _connectedUserId = userId;
    try {
      localRenderer.initialize();
    } catch (_) {}
    try {
      _remoteRenderer.initialize();
    } catch (_) {}

    //await _foregroundService.initializeService();

    callSocket.onConnect((_) {
      log("✅ Call socket connected for user: $userId");
      callSocket.emit('register', {"userId": userId, "fcmToken": token});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestRemainingMinutes();
      });
    });

    callSocket.onDisconnect((reason) {
      log("🔌 Call socket disconnected: $reason");
    });

    callSocket.on('reconnect', (_) {
      log("🔄 Call socket reconnected, re-registering user: $userId");
      callSocket.emit('register', {"userId": userId, "fcmToken": token});
      requestRemainingMinutes();
    });

    callSocket.on("low-time-alert", (data) async {
      final remaining = data['remaining'] ?? 0;
      final threshold = data['threshold'] ?? 0;
      final message = data['message'] ?? '';

      log("⚠️ Low time alert received: $remaining minutes left");

      // Emit the low time alert state
      emit(state.copyWith(
        lowTimeAlert: LowTimeAlert(
          remaining: remaining,
          threshold: threshold,
          message: message,
        ),
      ));

      // You can also vibrate or play a sound here
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 1000, pattern: [0, 500, 200, 500]);
      }
    });

    callSocket.on("remaining-daily-minutes", (data) {
      final remaining = data['remaining'] ?? 0;
      log("📊 Remaining daily minutes: $data");

      emit(state.copyWith(remainingMinutes: remaining));
      _remainingMinutesProvider?.updateRemainingMinutes(remaining);
    });

    // Listen for plan refresh response (after user explicitly requests refresh)
    callSocket.on("plan-refreshed", (data) {
      final success = data['success'] ?? false;
      final remainingMinutes = data['remainingMinutes'] ?? 0;

      log("🔄 Plan refreshed response: success=$success, remaining=$remainingMinutes");

      if (success) {
        emit(state.copyWith(remainingMinutes: remainingMinutes));
        _remainingMinutesProvider?.updateRemainingMinutes(remainingMinutes);
      }
    });

    // Listen for automatic plan updates (server pushes when plan changes)
    callSocket.on("plan-updated", (data) {
      final remainingMinutes = data['remainingMinutes'] ?? 0;
      final allowedSeconds = data['allowedSeconds'] ?? 600;
      final planId = data['planId'] ?? 1;

      log("📢 Plan updated notification: remaining=$remainingMinutes, planId=$planId, allowedSeconds=$allowedSeconds");

      emit(state.copyWith(remainingMinutes: remainingMinutes));
      _remainingMinutesProvider?.updatePlanData(
        remainingMinutes: remainingMinutes,
        allowedSeconds: allowedSeconds,
        planId: planId,
      );
    });

    callSocket.on('incoming-call', (data) async {
      final from = data['from'];
      final userName = data['userName'];

      int? findedIndex = friends
          .indexWhere((ele) => ele.friendId.toString() == from.toString());

      // Log incoming call regardless of whether caller is in friends list
      log("📞 Socket incoming-call event received from: $from, name: $userName, found in friends: ${findedIndex != -1}");

      if (findedIndex != -1) {
        // Caller is in friends list
        Future.delayed(Duration(seconds: 30), () {
          // Only dismiss the notification if call was NOT accepted
          if (!isLiveCallActive) {
            FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
            FlutterCallkitIncoming.endAllCalls();
          }
        });

        callerName = friends[findedIndex].friendName;
        targetUserId = int.parse(from ?? "0");
        await _syncCallerInfoToStorage();

        if (!Platform.isIOS) {
          showFlutterCallNotification(
            callSessionId: 'sdkjcslkcmslkcmsdc',
            userId: '$from',
            callerName: '${friends[findedIndex].friendName}',
            callerId: int.parse(from ?? "0"),
            receiverId: int.parse(userId ?? "0"),
          );
        }

        targetUserId = int.parse(from ?? "0");
      } else {
        // Caller is not in friends list - use userName from socket data
        log("⚠️ Caller $from not in friends list, using socket userName: $userName");

        Future.delayed(Duration(seconds: 30), () {
          // Only dismiss the notification if call was NOT accepted
          if (!isLiveCallActive) {
            FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
            FlutterCallkitIncoming.endAllCalls();
          }
        });

        callerName = userName ?? "Unknown";
        targetUserId = int.parse(from ?? "0");
        await _syncCallerInfoToStorage();

        if (!Platform.isIOS) {
          showFlutterCallNotification(
            callSessionId: 'sdkjcslkcmslkcmsdc',
            userId: '$from',
            callerName: callerName!,
            callerId: int.parse(from ?? "0"),
            receiverId: int.parse(userId ?? "0"),
          );
        }

        targetUserId = int.parse(from ?? "0");
      }
    });

    callSocket.on('call-accepted', (data) async {
      _cancelCallTimeoutTimer();

      await Future.delayed(const Duration(milliseconds: 500));
      await PushNotificationService.flutterLocalNotificationsPlugin
          .cancelAll(); // Clear incoming call notification
      emit(CallAccepted());

      isLiveCallActive = true;

      await _syncCallerInfoToStorage();

      if (targetUserId != null && callerName != null) {
        await _storeCallDataForService(targetUserId!, callerName!);
      }

      _foregroundService.startCallService(
        callerName: callerName ?? 'Unknown',
        targetUserId: targetUserId?.toString() ?? '0',
        isVideoCall: false,
      );

      await _foregroundService.callConnected();

      FlutterCallkitIncoming.setCallConnected("sdkjcslkcmslkcmsdc");

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
    });

    callSocket.on('call-rejected', (data) async {
      _cancelCallTimeoutTimer();
      isLiveCallActive = false;

      await _foregroundService.stopCallService();

      // Clean up locally WITHOUT sending 'end-call' back to server
      // (server already handled it - sending end-call here causes an event loop)
      await hangup();
      await FlutterCallkitIncoming.endAllCalls();
      if (Platform.isIOS) {
        try {
          const platform = MethodChannel('picturo_call_service');
          await platform.invokeMethod('endCall');
        } catch (e) {
          log("⚠️ iOS: Error ending call via MethodChannel in call-rejected: $e");
        }
      }
      await PushNotificationService.flutterLocalNotificationsPlugin
          .cancelAll(); // Clear notifications
      await CallInfoStorage.clearCallInfo();
      await _clearStoredCallData();
      requestRemainingMinutes();
      emit(CallRejected());
    });
    callSocket.on('call-error', (data) async {
      final String errorMessage = data['message'] ?? 'Unknown error';

      if (errorMessage.toLowerCase().contains('another call') ||
          errorMessage.toLowerCase().contains('already in call')) {}

      emit(CallErrorState(errorMessage));

      // await _foregroundService.stopCallService();
      // _cancelCallTimeoutTimer();
    });

    callSocket.on('signal', (data) async {
      final from = data['from'];
      final description = data['description'];
      final candidate = data['candidate'];
      final peerKey = from.toString();

      if (description != null) {
        final signalKey = '${peerKey}_${description['type']}';

        // Prevent duplicate concurrent processing of the same signal type per peer
        if (_processingSignal.contains(signalKey)) return;
        _processingSignal.add(signalKey);

        try {
          final rtcDesc =
              RTCSessionDescription(description['sdp'], description['type']);

          if (rtcDesc.type == 'offer') {
            // Only create a new peer connection if one doesn't already exist
            if (!peerConnections.containsKey(peerKey)) {
              await connectNewUser(from, int.parse(userId ?? '0'));
            }

            // Capture the PC reference once to avoid race conditions across awaits
            final pc = peerConnections[peerKey];
            if (pc == null) return;

            await pc.setRemoteDescription(rtcDesc);

            _localStream ??=
                await navigator.mediaDevices.getUserMedia({'audio': true});

            final answer = await pc.createAnswer();
            await pc.setLocalDescription(answer);

            callSocket.emit('signal', {
              'to': from,
              'from': userId,
              'description': answer.toMap(),
            });
          } else if (rtcDesc.type == 'answer') {
            final pc = peerConnections[peerKey];
            if (pc != null &&
                pc.signalingState !=
                    RTCSignalingState.RTCSignalingStateStable) {
              await pc.setRemoteDescription(rtcDesc);
            }
          }
        } catch (e) {
          log("⚠️ Error handling signal from $from: $e");
        } finally {
          _processingSignal.remove(signalKey);
        }
      }

      if (candidate != null) {
        final ice = RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        );
        await peerConnections[peerKey]?.addCandidate(ice);
      }
    });

    callSocket.on('call-ended', (data) async {
      // Skip if we already cleaned up locally (e.g., we called endCall() ourselves)
      // The other user who didn't initiate the end-call will still have isLiveCallActive=true
      if (!isLiveCallActive) {
        log("📞 call-ended received but call already ended locally, skipping duplicate cleanup");
        FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
        FlutterCallkitIncoming.endAllCalls();
        if (Platform.isIOS) {
          try {
            const platform = MethodChannel('picturo_call_service');
            await platform.invokeMethod('endCall');
          } catch (e) {
            log("⚠️ iOS: Error ending call via MethodChannel (early-exit): $e");
          }
        }
        return;
      }

      // iOS: ignore premature call-ended events fired within 3s of accepting
      // (CallKit sometimes fires this before WebRTC is fully established)
      if (Platform.isIOS && _callAcceptedTime != null) {
        final elapsed = DateTime.now().difference(_callAcceptedTime!);
        if (elapsed.inSeconds < 3) {
          log("⚠️ iOS: Ignoring premature call-ended (${elapsed.inSeconds}s after accept)");
          return;
        }
      }

      _cancelCallTimeoutTimer();

      isLiveCallActive = false;

      await _foregroundService.callDisconnected();

      await Future.delayed(Duration(seconds: 2));
      await _foregroundService.stopCallService();

      FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");

      await hangup();
      await FlutterCallkitIncoming.endAllCalls();
      if (Platform.isIOS) {
        try {
          const platform = MethodChannel('picturo_call_service');
          await platform.invokeMethod('endCall');
        } catch (e) {
          log("⚠️ iOS: Error ending call via MethodChannel in call-ended: $e");
        }
      }
      await PushNotificationService.flutterLocalNotificationsPlugin
          .cancelAll(); // Clear incoming call notification
      await CallInfoStorage.clearCallInfo();
      await _clearStoredCallData();
      requestRemainingMinutes();
      emit(CallRejected());
    });

    callSocket.on("call-hold", (_) {
      _muteLocalAudio(true);
      emit(CallOnHold());
    });

    callSocket.on("call-resume", (_) {
      emit(CallResumed());
    });

    callSocket.onError((err) {
      log("❌ Socket error: $err");
    });

    // Listen for native phone call interruptions (GSM/CDMA call while in VoIP call).
    // iOS: audio_session's interruptionEventStream is reliable when CallKit/Siri steals audio focus.
    // Android: audio_session does NOT reliably fire for telephony; use phone_state instead.
    _callKitEventListener?.cancel();
    if (Platform.isIOS) {
      final audioSession = await AudioSession.instance;
      _callKitEventListener = audioSession.interruptionEventStream.listen((event) {
        if (!isLiveCallActive) return;
        if (event.begin) {
          _isSystemCallActive = true;
          onNativeCallStart(); // mutes app call + emits CallOnHold
          log("📵 [iOS] Native call interrupted — app call muted and held");
        } else if (_isSystemCallActive) {
          _isSystemCallActive = false;
          onNativeCallEnd(); // unmutes app call + emits CallResumed
          log("📵 [iOS] Native call ended — app call resumed");
        }
      });
    } else {
      // Android: phone_state package monitors telephony state changes directly.
      // Requires READ_PHONE_STATE permission (declared in AndroidManifest.xml).
      _callKitEventListener = PhoneState.stream.listen((phoneState) {
        if (!isLiveCallActive) return;
        log("📵 [Android] Phone state: ${phoneState.status}");
        if (phoneState.status == PhoneStateStatus.CALL_INCOMING ||
            phoneState.status == PhoneStateStatus.CALL_STARTED) {
          if (!_isSystemCallActive) {
            _isSystemCallActive = true;
            onNativeCallStart(); // mutes app call + emits CallOnHold
            log("📵 [Android] Native call active — app call muted and held");
          }
        } else if (phoneState.status == PhoneStateStatus.CALL_ENDED ||
            phoneState.status == PhoneStateStatus.NOTHING) {
          if (_isSystemCallActive) {
            _isSystemCallActive = false;
            onNativeCallEnd(); // unmutes app call + emits CallResumed
            log("📵 [Android] Native call ended — app call resumed");
          }
        }
      });
    }
  }

  Future<void> postCallLog({
    required String receiverId,
    required String callType,
    required String status,
    required int duration,
  }) async {
    final url = Uri.parse('https://picturoenglish.com/api/call_log_add.php');
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    final body = {
      'receiver_id': receiverId,
      'call_type': callType,
      'status': "completed",
      'duration': duration,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );
      print('Call log added successfully: ${response.body} __ $body');
      if (response.statusCode == 200) {
      } else {
        if (kDebugMode) {
          print('Failed to add call log. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (e) {
      print('Error posting call log: $e');
    }
  }

  Future<void> sendCallEndNotification(int userId) async {
    final url = Uri.parse(
            'https://picturoenglish.com/api/callend-fcm-push-notifications.php')
        .replace(queryParameters: {
      'user_id': userId.toString(),
      'type': "end_call",
    });

    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        log("✅ Call end FCM push notification sent: ${response.body}");
      } else {
        log("⚠️ Failed to send call end notification. Code: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      log("❌ Error sending call end notification: $e");
    }
  }

  // void updateCallDurationNotification(String duration) {
  //   _foregroundService.updateCallDuration(duration);
  // }

  void listenEvent(String event, Function(dynamic) callback) {
    callSocket.on(event, callback);
  }

  bool isCallSocketConnected() {
    return _isSocketInitialized && callSocket.active;
  }

  void onNativeCallStart() {
    if (state is! CallOnHold) {
      callSocket.emit("call-hold", {"to": targetUserId});
      _muteLocalAudio(true);   // silence your outgoing mic
      _muteRemoteAudio(true);  // silence incoming VoIP audio so you don't hear both voices
      emit(CallOnHold());
    }
  }

  void onNativeCallEnd() {
    if (state is CallOnHold && state is! CallResumed) {
      callSocket.emit("call-resume", {"to": targetUserId});
      _muteLocalAudio(false);   // restore your outgoing mic
      _muteRemoteAudio(false);  // restore incoming VoIP audio
      emit(CallResumed());
    }
  }

  /// Mutes/unmutes incoming audio from all remote peers (receivers).
  /// Used during native phone call interruptions so the user doesn't hear both voices.
  /// NOT used for the regular in-app mute button (which only affects outgoing mic).
  void _muteRemoteAudio(bool isMuted) {
    peerConnections.forEach((key, pc) async {
      final receivers = await pc.getReceivers();
      for (var receiver in receivers) {
        if (receiver.track != null && receiver.track!.kind == 'audio') {
          receiver.track!.enabled = !isMuted;
        }
      }
    });
  }

  void _muteLocalAudio(bool isMuted) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }

    peerConnections.forEach((key, pc) async {
      final senders = await pc.getSenders();
      for (var sender in senders) {
        if (sender.track != null && sender.track!.kind == 'audio') {
          sender.track!.enabled = !isMuted;
        }
      }
    });
  }

  void acceptCall(int targetUser, {String? callerName}) async {
    try {
      // Ensure socket is initialized before proceeding
      if (!_isSocketInitialized) {
        await initCallSocket();
      }

      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("user_id");
      int currentUserId = int.parse(userId ?? "0");

      this.targetUserId = targetUser;
      if (callerName != null && callerName.isNotEmpty) {
        this.callerName = callerName;
      }
      await _syncCallerInfoToStorage();

      _callAcceptedTime = DateTime.now();
      await prepareIOSMic(); // iOS: configure audio session BEFORE WebRTC grabs mic

      await connectNewUser(targetUser, currentUserId);
      initiateWebRTCCall(
        targetId: targetUser,
        currentUserId: currentUserId,
      );

      callSocket.emit("call-accepted", {"to": targetUser});
      isLiveCallActive = true;

      //await AppLifecycleService().onCallStarted(targetUser);

      // await _foregroundService.startForegroundService(
      //   callerName: callerName ?? 'Unknown',
      //   callDuration: '00:00',
      //   isVideoCall: false,
      // );
      await _foregroundService.startCallService(
        callerName: callerName ?? 'Unknown',
        targetUserId: targetUserId?.toString() ?? '0',
        isVideoCall: false,
      );

      await _foregroundService.callConnected();
      await _notifyIOSCallConnected();

      await Future.delayed(const Duration(milliseconds: 500));
      emit(CallAccepted());
    } catch (e) {
      log("❌ Error accepting call: $e");
      emit(CallErrorState("Failed to accept call: $e"));
    }
  }

  void handleCallNotConnected() async {
    if (!isLiveCallActive) {
      await _foregroundService.stopCallService();
    }
  }

  void emitCallingFunction({
    required int currentUserId,
    required int targetId,
    required String targettedUserName,
  }) {
    callerName = targettedUserName;
    targetUserId = targetId;
    _syncCallerInfoToStorage();

    log("📞 Initiating call to $targettedUserName (ID: $targetId)");

    // _foregroundService.startCallService(
    //   callerName: targettedUserName,
    //   isVideoCall: false,
    // );

    _startCallTimeoutTimer();

    print("ldkjmclksdmclkdsc _ ${{
      'from': currentUserId,
      'to': targetId,
      "userName": targettedUserName
    }} _${{
      'from': currentUserId,
      'to': targetId
    }} ${_isSocketInitialized ? callSocket.connected : 'Not Initialized'}");

    callSocket.emit('call-user', {
      'from': currentUserId,
      'to': targetId,
      "type": "incoming_call",
      "caller_id": currentUserId, // ✅ safe replacement
      "receiver_id": targetId,
      "deep_link": "/call/$currentUserId"
    });

    callSocket.emit('incoming-call',
        {'from': currentUserId, 'to': targetId, "userName": targettedUserName});
  }

  void _startCallTimeoutTimer() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(Duration(seconds: _callTimeoutSeconds), () async {
      if (!isLiveCallActive) {
        log("⏰ Call timeout - no answer within $_callTimeoutSeconds seconds");

        // ✅ Stop service on timeout
        await _foregroundService.stopCallService();

        // Send call end notification if needed
        if (targetUserId != null) {
          await sendCallEndNotification(targetUserId!);
        }

        handleCallNotConnected();
        emit(CallErrorState("Call timed out"));

        // End the call properly
        await endCall();
      }
    });
  }

  void _cancelCallTimeoutTimer() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }

  Future<void> initiateWebRTCCall({
    required int currentUserId,
    required int targetId,
  }) async {
    await prepareIOSMic(); // iOS: configure audio session before WebRTC grabs mic (caller side)
    targetUserId = targetId;
    emit(state);
    await connectNewUser(targetId, currentUserId);
    final offer = await peerConnections[targetId.toString()]!.createOffer();
    await peerConnections[targetId.toString()]!.setLocalDescription(offer);

    callSocket.emit('signal', {
      'to': targetUserId,
      'from': currentUserId,
      'description': offer.toMap(),
    });
  }

  Future<void> connectNewUser(int userId, int currentUserId) async {
    await Helper.setSpeakerphoneOn(false);

    final pc = await createPeerConnection(_config);

    // request mic
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true});

    _localStream!
        .getTracks()
        .forEach((track) => pc.addTrack(track, _localStream!));

    // iOS: explicitly enable all audio tracks after adding to peer connection
    if (Platform.isIOS) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }
    }

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        callSocket.emit('signal', {
          'to': userId,
          'from': currentUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        });
      }
    };

    pc.onTrack = (event) async {
      final stream = event.streams.first;
      if (!remoteRenderers.containsKey(userId.toString())) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        remoteRenderers[userId.toString()] = renderer;
      }
      remoteRenderers[userId.toString()]?.srcObject = stream;
    };

    peerConnections[userId.toString()] = pc;
  }

  Future<void> muteACall(bool isMuted) async {
    // Mute/unmute local stream
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }

    // Mute/unmute outgoing audio tracks for each peer connection
    for (var entry in peerConnections.entries) {
      final pc = entry.value;
      final senders = await pc.getSenders(); // Await here ✅

      for (var sender in senders) {
        final track = sender.track;
        if (track != null && track.kind == 'audio') {
          track.enabled = !isMuted;
        }
      }
    }
  }

  Future<void> releaseAudioFocus() async {
    if (Platform.isIOS) return; // iOS: CallKit manages audio session lifecycle
    final session = await AudioSession.instance;
    await session.setActive(false);
  }

  Future<void> hangup() async {
    isLiveCallActive = false;
    emit(state);

    if (isLiveCallActive == true) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
    }

    await releaseAudioFocus();

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track.stop();
      }
      _localStream!.dispose();
      _localStream = null;
    }

    // Clear local video renderer (don't dispose - it persists for the cubit's lifetime
    // and will be reused for the next call)
    try {
      localRenderer.srcObject = null;
    } catch (e) {
      print("Error clearing localRenderer: $e");
    }

    // Close and dispose all peer connections
    // Use a snapshot (toList) to avoid "Concurrent modification during iteration"
    // because pc.close()/dispose() can trigger native callbacks that modify the map
    for (var pc in peerConnections.values.toList()) {
      try {
        await pc.close();
        await pc.dispose(); // Important: Free the native resources
      } catch (e) {
        print("Error disposing peer connection: $e");
      }
    }
    peerConnections.clear();
    _processingSignal.clear();

    // Dispose all remote video renderers
    await disposeRemoteRender();
  }

  // Don't forget to dispose renderers when the widget is no longer needed
  void disposeRenderers() {
    localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  Future<bool> endCall() async {
    try {
      // Do all cleanup FIRST before emitting state change
      // (emit triggers BlocConsumer listeners which can throw if widget is deactivated)
      _callAcceptedTime = null;
      if (_isSocketInitialized) {
        callSocket.emit('end-call', {'to': targetUserId});
      }

      if (isLiveCallActive == true) {
        await _foregroundService.stopCallService();
      }

      await hangup();
      await FlutterCallkitIncoming.endAllCalls();
      if (Platform.isIOS) {
        try {
          const platform = MethodChannel('picturo_call_service');
          await platform.invokeMethod('endCall');
        } catch (e) {
          log("⚠️ iOS: Error ending call via MethodChannel in endCall: $e");
        }
      }
      await PushNotificationService.flutterLocalNotificationsPlugin
          .cancelAll(); // Clear notifications
      await _clearStoredCallData();
      await CallInfoStorage.clearCallInfo();
      requestRemainingMinutes();

      // Emit state change LAST - this triggers UI listeners
      emit(CallRejected());

      return true;
    } catch (e) {
      log("❌ Error ending call: $e");
      emit(CallErrorState("Failed to end call: $e"));
      return false;
    }
  }

  Future<void> disposeLocalRender() async {
    try {
      if (localRenderer.srcObject != null) {
        final tracks = localRenderer.srcObject!.getTracks();
        for (var track in tracks) {
          track.stop();
        }
        localRenderer.srcObject!.getAudioTracks().clear();
        localRenderer.srcObject!.getVideoTracks().clear();
        localRenderer.srcObject = null;
      }
      await localRenderer.dispose();
    } catch (e) {
      print("Error disposing localRenderer: $e");
    }
  }

  Future<void> disposeRemoteRender() async {
    for (final entry in remoteRenderers.entries.toList()) {
      final key = entry.key;
      final renderer = entry.value;
      if (renderer.srcObject != null) {
        final audioTracks = renderer.srcObject!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          for (var track in audioTracks) {
            track.stop();
          }
        }

        final videoTracks = renderer.srcObject!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          for (var track in videoTracks) {
            track.stop();
          }
        }

        renderer.srcObject!.getAudioTracks().clear();
        renderer.srcObject!.getVideoTracks().clear();
      } else {
        print('No srcObject found for renderer $key');
      }

      try {
        await renderer.dispose();
      } catch (e) {
        print('Error disposing remote renderer $key: $e');
      }
    }
    remoteRenderers.clear();
  }

  Future<void> resetCubit() async {
    final currentMinutes = state.remainingMinutes;
    targetUserId = null;
    callerName = null;
    _callAcceptedTime = null;

    await CallInfoStorage.clearCallInfo();

    emit(CallSocketHandleInitial().copyWith(
      remainingMinutes: currentMinutes,
    ));

    _remainingMinutesProvider?.updateRemainingMinutes(currentMinutes);
    requestRemainingMinutes();
  }

  /// Full reset for logout - clears ALL data including remaining minutes
  Future<void> fullResetForLogout() async {
    log("🧹 Starting CallSocketHandleCubit full reset...");

    targetUserId = null;
    callerName = null;
    _callAcceptedTime = null;
    isLiveCallActive = false;
    remainingMinutesRequestCount = 0;
    _remainingMinutesProvider = null;

    await CallInfoStorage.clearCallInfo();
    await _clearStoredCallData();

    // Force disconnect and destroy the call socket completely
    if (_isSocketInitialized) {
      try {
        // Remove all listeners first to prevent auto-reconnect
        callSocket.clearListeners();
        log("✅ Call socket listeners cleared");
      } catch (e) {
        log("⚠️ Error clearing listeners: $e");
      }

      try {
        // Disable reconnection before disconnecting
        callSocket.io.options?['reconnection'] = false;
        callSocket.disconnect();
        log("✅ Call socket disconnected");
      } catch (e) {
        log("⚠️ Error disconnecting call socket: $e");
      }

      try {
        callSocket.dispose();
        log("✅ Call socket disposed");
      } catch (e) {
        log("⚠️ Error disposing call socket: $e");
      }

      try {
        callSocket.destroy();
        log("✅ Call socket destroyed");
      } catch (e) {
        log("⚠️ Error destroying call socket: $e");
      }
    }

    _callKitEventListener?.cancel();
    _callKitEventListener = null;
    _isSystemCallActive = false;
    _isSocketInitialized = false;
    _connectedUserId = null;

    emit(CallSocketHandleInitial());
    log("🧹 CallSocketHandleCubit fully reset for logout - DONE");
  }
}

void showFlutterCallNotification({
  required String callSessionId,
  required String userId,
  required String callerName,
  int callerId = 0,
  int receiverId = 0,
  String? avatar,
}) async {
  String? avatarUrl;
  if (avatar != null && avatar.isNotEmpty && avatar != "0") {
    try {
      final apiService = await ApiService.create();
      final avatarResponse = await apiService.fetchAvatars();
      final avatarData = avatarResponse.data.firstWhere(
        (element) => element.id.toString() == avatar,
        orElse: () => throw Exception("Avatar not found"),
      );
      avatarUrl = "http://picturoenglish.com/admin/${avatarData.avatarUrl}";
    } catch (e) {
      log("Error fetching avatar url: $e");
    }
  }

  final params = CallKitParams(
    id: callSessionId,
    nameCaller: callerName,
    appName: 'Picturo',
    handle: "  Call From $callerName",
    type: 0,
    duration: 30000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      subtitle: 'Missed call',
    ),
    avatar: avatarUrl,
    extra: <String, dynamic>{
      'userId': '$userId',
      'callerId': callerId.toString(),
      'receiverId': receiverId.toString(),
      'avatar': avatar,
    },
    android: const AndroidParams(
      isCustomNotification: false,
      isShowLogo: true,
      isShowCallID: true,
      isShowFullLockedScreen: true,
      isImportant: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#ffffff',
      actionColor: '#FF8C00',
      textColor: '#FF8C00',
    ),
    ios: IOSParams(
      iconName: callerName,
      handleType: '',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

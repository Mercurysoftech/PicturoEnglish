import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:audio_session/audio_session.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
  int? targetUserId;
  String? callerName;
  Timer? _callTimeoutTimer;
  final int _callTimeoutSeconds = 30;

  RemainingMinutesProvider? _remainingMinutesProvider;
  bool _isSystemCallActive = false;
  StreamSubscription? _callKitEventListener;

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
    callSocket.emit("mute-call", {"to": targetUserId, "muted": newMuteState});

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
    callSocket.dispose();
  }

  void requestRemainingMinutes() {
    if (callSocket.connected) {
      callSocket.emit("get-remaining-daily-minutes");
      log("📊 Requesting remaining minutes...");
    } else {
      log("⚠️ Socket not connected, cannot request remaining minutes");
    }
  }

  Future<void> initCallSocket() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");

    //await _foregroundService.initializeService();

    callSocket = IO.io(
      'https://picturoenglish.com:2027',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({
            'userId': userId,
            'fcmToken': token,
          })
          .build(),
    );

    callSocket.connect();
    localRenderer.initialize();
    _remoteRenderer.initialize();

    //await _foregroundService.initializeService();

    callSocket.onConnect((_) {
      callSocket.emit('register', {"userId": userId, "fcmToken": token});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestRemainingMinutes();
      });
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

    callSocket.on('incoming-call', (data) async {
      final from = data['from'];
      final userName = data['userName'];

      int? findedIndex = friends
          .indexWhere((ele) => ele.friendId.toString() == from.toString());
      if (findedIndex != -1) {
        Future.delayed(Duration(seconds: 30), () {
          FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
          FlutterCallkitIncoming.endAllCalls();
        });
        callerName = friends[findedIndex].friendName;

        showFlutterCallNotification(
          callSessionId: 'sdkjcslkcmslkcmsdc',
          userId: '$from',
          callerName: '${friends[findedIndex].friendName}',
          callerId: int.parse(from ?? "0"),
          receiverId: int.parse(userId ?? "0"),
        );

        targetUserId = int.parse(from ?? "0");
      }
    });

    callSocket.on('call-accepted', (data) async {
      _cancelCallTimeoutTimer();

      emit(CallAccepted());
      isLiveCallActive = true;

      // Store call data for service
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
      // Extract caller ID from the rejection data if available
      // final callerId = data['caller_id'] ?? targetUserId;
      // if (callerId != null) {
      //   await rejectCallWithApi(callerId);
      // }
      //await _foregroundService.stopForegroundService();
      _cancelCallTimeoutTimer();
      isLiveCallActive = false;

      await _foregroundService.stopCallService();

      endCall();
    });

    // In CallSocketHandleCubit - update the call-error handler
    callSocket.on('call-error', (data) async {
      final String errorMessage = data['message'] ?? 'Unknown error';

      // Check if it's a "another call" error
      if (errorMessage.toLowerCase().contains('another call') ||
          errorMessage.toLowerCase().contains('already in call')) {}

      emit(CallErrorState(errorMessage));

      // // Also stop services if needed
      // await _foregroundService.stopCallService();
      // _cancelCallTimeoutTimer();
    });

    callSocket.on('signal', (data) async {
      final from = data['from'];
      final description = data['description'];
      final candidate = data['candidate'];

      // ✅ FIX: prevent null SDP bug
      if (description == null) {
        log("⚠️ Received null description from $from");
      } else {
        final rtcDesc =
            RTCSessionDescription(description['sdp'], description['type']);

        if (rtcDesc.type == 'offer') {
          await connectNewUser(from, int.parse(userId ?? '0'));
          await peerConnections[from.toString()]?.setRemoteDescription(rtcDesc);

          _localStream ??=
              await navigator.mediaDevices.getUserMedia({'audio': true});

          final answer = await peerConnections[from.toString()]!.createAnswer();
          await peerConnections[from.toString()]!.setLocalDescription(answer);

          callSocket.emit('signal', {
            'to': from,
            'from': userId,
            'description': answer.toMap(),
          });
        } else if (rtcDesc.type == 'answer') {
          await peerConnections[from.toString()]?.setRemoteDescription(rtcDesc);
        }
      }

      if (candidate != null) {
        final ice = RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        );
        await peerConnections[from.toString()]?.addCandidate(ice);
      }
    });

    callSocket.on('call-ended', (data) async {
      _cancelCallTimeoutTimer();

      isLiveCallActive = false;

      await _foregroundService.callDisconnected();

      await Future.delayed(Duration(seconds: 2));
      await _foregroundService.stopCallService();

      FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");

      await hangup();
      await FlutterCallkitIncoming.endAllCalls();
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
    return callSocket.active;
  }

  void onNativeCallStart() {
    if (state is! CallOnHold) {
      callSocket.emit("call-hold", {"to": targetUserId});
      _muteLocalAudio(true);
      emit(CallOnHold());
    }
  }

  void onNativeCallEnd() {
    if (state is CallOnHold && state is! CallResumed) {
      callSocket.emit("call-resume", {"to": targetUserId});
      _muteLocalAudio(false);
      emit(CallResumed());
    }
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

  void acceptCall(int targetUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("user_id");
      int currentUserId = int.parse(userId ?? "0");
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
    }} _${{'from': currentUserId, 'to': targetId}} ${callSocket.connected}");

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

    // Clear local video renderer
    try {
      localRenderer.srcObject = null;
      await localRenderer.dispose(); // Properly dispose the renderer
    } catch (e) {
      print("Error disposing localRenderer: $e");
    }

    // Close and dispose all peer connections
    for (var pc in peerConnections.values) {
      try {
        await pc.close();
        await pc.dispose(); // Important: Free the native resources
      } catch (e) {
        print("Error disposing peer connection: $e");
      }
    }
    peerConnections.clear();

    // Dispose all remote video renderers
    await disposeRemoteRender();
  }

  // Don't forget to dispose renderers when the widget is no longer needed
  void disposeRenderers() {
    localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  Future<bool> endCall() async {
    // if(userOpenCallingPage){
    try {
      emit(CallRejected());
      await _clearStoredCallData();
      // }
      //await AppLifecycleService().onCallEnded();
      //await _foregroundService.callDisconnected();
      if (isLiveCallActive == true) {
        await _foregroundService.stopCallService();
      }

      callSocket.emit('end-call', {'to': targetUserId});
      await hangup();

      // await Future.delayed(Duration(seconds: 1));
      // await _foregroundService.stopCallService();

      await FlutterCallkitIncoming.endAllCalls();
      requestRemainingMinutes();

      return true;
    } catch (e) {
      log("❌ Error ending call: $e");
      emit(CallErrorState("Failed to end call: $e"));
      return false;
    }
  }

  Future<void> disposeLocalRender() async {
    List<MediaStreamTrack> data = localRenderer.srcObject!.getTracks();
    for (var track in data) {
      track.stop();
    }
    if (localRenderer.srcObject != null) {
      final audioTracks = localRenderer.srcObject!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        for (var track in audioTracks) {
          track.stop();
        }
      }

      final videoTracks = localRenderer.srcObject!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        for (var track in videoTracks) {
          track.stop();
        }
      }

      localRenderer.srcObject!.getAudioTracks().clear();
      localRenderer.srcObject!.getVideoTracks().clear();
    }

    await localRenderer.dispose();
  }

  Future<void> disposeRemoteRender() async {
    remoteRenderers.forEach((key, renderer) async {
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

      await renderer.dispose();
    });
  }

  Future<void> resetCubit() async {
    final currentMinutes = state.remainingMinutes;

    emit(CallSocketHandleInitial().copyWith(
      remainingMinutes: currentMinutes,
    ));

    _remainingMinutesProvider?.updateRemainingMinutes(currentMinutes);
    requestRemainingMinutes();
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
    extra: <String, dynamic>{
      'userId': '$userId',
      'callerId': callerId.toString(),
      'receiverId': receiverId.toString(),
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

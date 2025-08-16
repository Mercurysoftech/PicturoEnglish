import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:audio_session/audio_session.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:http/http.dart' as http;
import '../../responses/allusers_response.dart';
import '../../responses/friends_response.dart';
import '../../services/api_service.dart';

part 'call_socket_handle_state.dart';

class CallSocketHandleCubit extends Cubit<CallSocketHandleState> {
  CallSocketHandleCubit() : super(CallSocketHandleInitial());

  late IO.Socket callSocket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool isLiveCallActive=false;

  List<Friends> friends = [];
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Map<String, RTCPeerConnection> peerConnections = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  int? targetUserId;
  String?  callerName;


  final _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };
   void userOpenCalling(){
     // userOpenCallingPage=true;
   }
   void userCloseCalling(){
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
  void disposeScoket(){
    callSocket.dispose();
  }

  Future<void> initCallSocket({required int currentUserId}) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    callSocket = IO.io(
        'https://picturoenglish.com:2027',
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .disableAutoConnect()
            .setQuery({
          'userId': currentUserId,
          'fcmToken': token,
        })
            .build(),);

    callSocket.connect();
    localRenderer.initialize();
    _remoteRenderer.initialize();

    callSocket.onConnect((_) {
      callSocket.emit('register', {
        "userId": currentUserId,
        "fcmToken": token
      });
    });



    callSocket.on('incoming-call', (data) async {
      final from = data['from'];
      final userName = data['userName'];


      int? findedIndex = friends.indexWhere((ele) => ele.friendId.toString() == from.toString());
      if (findedIndex != -1) {
        Future.delayed(Duration(seconds: 30), () {
          FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
          FlutterCallkitIncoming.endAllCalls();
        });
        callerName=friends[findedIndex].friendName;

        showFlutterCallNotification(
          callSessionId: 'sdkjcslkcmslkcmsdc',
          userId: '$from',
          callerName: '${friends[findedIndex].friendName}',
        );

        targetUserId = int.parse(from??"0");
      }
    });
    callSocket.on('call-accepted', (data) {
      emit(CallAccepted());
      isLiveCallActive=true;
      FlutterCallkitIncoming.setCallConnected("sdkjcslkcmslkcmsdc");
    });

    callSocket.on('call-rejected', (_) {


      endCall();
    });



    callSocket.on('signal', (data) async {
      final from = data['from'];
      final description = data['description'];
      final candidate = data['candidate'];

      if (description != null) {
        final rtcDesc = RTCSessionDescription(description['sdp'], description['type']);

        if (rtcDesc.type == 'offer') {
          await connectNewUser(from, currentUserId);
          await peerConnections[from.toString()]?.setRemoteDescription(rtcDesc);

          final answer = await peerConnections[from.toString()]!.createAnswer();
          await peerConnections[from.toString()]!.setLocalDescription(answer);

          callSocket.emit('signal', {
            'to': from,
            'from': currentUserId,
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

    callSocket.on('call-ended', (data)async {
      isLiveCallActive=false;
      // if(userOpenCallingPage){
        emit(CallRejected());
      // }
      FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");

      await hangup();
      await FlutterCallkitIncoming.endAllCalls();
    });

    callSocket.on("call-hold",(_){
      _muteLocalAudio(true);
      emit(CallOnHold());
    });

    callSocket.on("call-resume",(_){
      _muteLocalAudio(false);
      emit(CallResumed());
    });
    callSocket.onError((err) {
    });
  }

  Future<void> postCallLog({
    required String receiverId,
    required String callType,
    required String status,
    required int duration,
  }) async {
    final url = Uri.parse('https://picturoenglish.com/api/call_log_add.php');
    SharedPreferences pref =await SharedPreferences.getInstance();
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
      print('Call log added successfully: ${response.body} __ ${body}');
      if (response.statusCode == 200) {

      } else {
        print('Failed to add call log. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error posting call log: $e');
    }
  }
  void listenEvent(String event, Function(dynamic) callback) {
    callSocket.on(event, callback);
  }
  bool isCallSocketConnected() {

   return callSocket.active;
  }

  void onNativeCallStart() {

    if(state is! CallOnHold){
      callSocket.emit("call-hold", {"to": targetUserId});
      _muteLocalAudio(true);
      emit(CallOnHold());
    }

  }

  void onNativeCallEnd() {
    if(state is CallOnHold&&state is! CallResumed){
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
    final prefs = await SharedPreferences.getInstance();
    String? userId= prefs.getString("user_id");
    int currentUserId =int.parse(userId??"0");
    await connectNewUser(targetUser, currentUserId);
    initiateWebRTCCall(targetId: targetUser, currentUserId: currentUserId,);

    callSocket.emit("call-accepted", {"to": targetUser});
    isLiveCallActive=true;
    emit(CallAccepted());
  }

  void emitCallingFunction({
    required int currentUserId,
    required int targetId,
    required String targettedUserName,
  }){
    callerName=targettedUserName;
    targetUserId=targetId;

    print("ldkjmclksdmclkdsc _ ${ {
      'from': currentUserId,
      'to': targetId,
      "userName": targettedUserName
    }} _${{'from': currentUserId, 'to': targetId}} ${callSocket.connected}");
    callSocket.emit('call-user', {
      'from': currentUserId,
      'to': targetId,
    "type": "incoming_call",
    "caller_id": currentUserId,           // ✅ safe replacement
    "receiver_id": targetId,
    "deep_link": "/call/${currentUserId}"
    });

    callSocket.emit('incoming-call', {
      'from': currentUserId,
      'to': targetId,
      "userName": targettedUserName
    });
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
    final localStream = await navigator.mediaDevices.getUserMedia({'audio': true});

    localStream.getTracks().forEach((track) => pc.addTrack(track, localStream));

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
    isLiveCallActive=false;
    emit(state);

    await releaseAudioFocus();
    // Stop and dispose local stream

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track.stop(); // Stops mic & camera
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

      emit(CallRejected());
    // }
    callSocket.emit('end-call', {'to': targetUserId});
    await hangup();
    await FlutterCallkitIncoming.endAllCalls();
    return true;
  }
  Future<void> disposeLocalRender() async {

    List<MediaStreamTrack> data=localRenderer.srcObject!.getTracks();
    data.forEach((track){
      track.stop();
    });
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



  Future<void> resetCubit()async {
    emit(CallSocketHandleInitial());
  }
}

void showFlutterCallNotification({
  required String callSessionId,
  required String userId,
  required String callerName,
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
    extra: <String, dynamic>{'userId': '$userId'},
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
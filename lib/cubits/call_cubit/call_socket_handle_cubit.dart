import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

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

  Future<void> initCallSocket({required int currentUserId}) async {

    callSocket = IO.io('https://picturoenglish.com:2027', {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    callSocket.connect();
    localRenderer.initialize();
    _remoteRenderer.initialize();
    callSocket.onConnect((_) {
      callSocket.emit('register', currentUserId);
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
        targetUserId = from;
      }
    });

    callSocket.on('call-accepted', (data) {
      print("Accepted $data ");
      emit(CallAccepted());
      isLiveCallActive=true;
      FlutterCallkitIncoming.setCallConnected("sdkjcslkcmslkcmsdc");
    });

    callSocket.on('call-rejected', (_) {
      endCall(targetUserId: targetUserId??0);
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

    callSocket.on('call-ended', (_)async {
      isLiveCallActive=false;
      emit(CallRejected());
    });


    callSocket.onError((err) {
      print("Socket error: $err");
    });
  }

  void acceptCall(int targetUser, int currentUserId) async {
    await connectNewUser(targetUser, currentUserId);
    initiateWebRTCCall(targetId: targetUser, currentUserId: currentUserId,);

    callSocket.emit("call-accepted", {"to": targetUser});
    isLiveCallActive=true;
    emit(CallAccepted());
  }

  Future<void> emitCallingFunction({
    required int currentUserId,
    required int targetId,
    required String targettedUserName,
})async{
    callSocket.emit('call-user', {'from': currentUserId, 'to': targetId});
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
      print("Incoming stream from user $userId");
      if (!remoteRenderers.containsKey(userId.toString())) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        remoteRenderers[userId.toString()] = renderer;
      }
      remoteRenderers[userId.toString()]?.srcObject = stream;
    };

    peerConnections[userId.toString()] = pc;
  }
  void muteACall(bool isMuted){
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = false;

    }
  }
  Future<void> releaseAudioFocus() async {
    final session = await AudioSession.instance;
    await session.setActive(false);
  }
  Future<void> hangup() async {
    isLiveCallActive=false;
    emit(state);
    print('Attempting to hang up the call...');
   await releaseAudioFocus();
    // Stop and dispose local stream

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track.stop(); // Stops mic & camera
      }
      await _localStream!.dispose();
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

    print('Call fully disconnected and mic/camera stopped.');
  }

  // Don't forget to dispose renderers when the widget is no longer needed
  void disposeRenderers() {
    localRenderer.dispose();
    _remoteRenderer.dispose();
    print('Renderers disposed.');
  }
  Future<void> endCall({required int targetUserId}) async {
    await hangup();
    callSocket.emit('end-call', {'to': targetUserId});
    await FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
    await FlutterCallkitIncoming.endAllCalls();
    emit(CallRejected());
    print("📴 Call completely cut for both users.");
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
            print('Stopping audio track for renderer $key');
            track.stop();
          }
        }

        final videoTracks = renderer.srcObject!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          for (var track in videoTracks) {
            print('Stopping video track for renderer $key');
            track.stop();
          }
        }

        renderer.srcObject!.getAudioTracks().clear();
        renderer.srcObject!.getVideoTracks().clear();
      } else {
        print('No srcObject found for renderer $key');
      }

      await renderer.dispose();
      print('Renderer $key disposed');
    });
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

  void resetCubit() {
    emit(CallSocketHandleInitial());
  }
}

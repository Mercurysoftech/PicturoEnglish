import 'dart:async';
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
  List<Friends> friends = [];
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Map<String, RTCPeerConnection> peerConnections = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  late int targetUserId;

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

    callSocket.onConnect((_) {
      callSocket.emit('register', currentUserId);
    });

    callSocket.on('incoming-call', (data) async {
      final from = data['from'];
      final userName = data['userName'];
      print("Incoming call from $data");
      int? findedIndex = friends.indexWhere((ele) => ele.friendId.toString() == from.toString());
      if (findedIndex != -1) {
        Future.delayed(Duration(seconds: 30), () {
          FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
          FlutterCallkitIncoming.endAllCalls();
        });
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
      FlutterCallkitIncoming.setCallConnected("sdkjcslkcmslkcmsdc");
    });

    callSocket.on('call-rejected', (_) {
      emit(CallRejected());
      endCall(targetUserId: targetUserId);
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

    callSocket.on('call-ended', (_) {
      print("Call ended by remote");
      emit(CallRejected());
    });

    callSocket.onError((err) {
      print("Socket error: $err");
    });
  }

  void acceptCall(int targetUser, int currentUserId) async {
    await connectNewUser(targetUser, currentUserId);
    callSocket.emit("call-accepted", {"to": targetUser});
    emit(CallAccepted());
  }

  Future<void> initiateWebRTCCall({
    required int currentUserId,
    required int targetId,
    required String targettedUserName,
  }) async {
    targetUserId = targetId;
    await connectNewUser(targetId, currentUserId);
    final offer = await peerConnections[targetId.toString()]!.createOffer();
    await peerConnections[targetId.toString()]!.setLocalDescription(offer);

    callSocket.emit('call-user', {'from': currentUserId, 'to': targetUserId});
    callSocket.emit('incoming-call', {
      'from': currentUserId,
      'to': targetUserId,
      "userName": targettedUserName
    });
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

  void endCall({required int targetUserId}) {
    FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
    FlutterCallkitIncoming.endAllCalls();

    _peerConnection?.close();

    _peerConnection?.dispose();

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();


    callSocket.emit('end-call', {'to': targetUserId});
    emit(CallRejected());
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

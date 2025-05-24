import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum CallState { idle, ringing, outgoing, connected }

class AudioCallPage extends StatefulWidget {
  const AudioCallPage({super.key});

  @override
  _AudioCallPageState createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  late IO.Socket socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _roomId;
  bool _isMuted = false;
  late DateTime _startTime;
  Timer? _timer;
  String _callDuration = "00:00";
  CallState _callState = CallState.idle;

  final _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {


    socket.on('connect', (_) => print('Connected to socket'));

    socket.on('room-created', (data) {
      _roomId = data['roomId'];
      print("dflkmvldkfvmdlkvmdlfvkdmfv ____ ${data}");
      setState(() => _callState = CallState.outgoing);
      _listenForUserJoined();
    });

    socket.on('room-joined', (data) {
      _roomId = data['roomId'];
      setState(() => _callState = CallState.connected);
    });

    socket.on('incoming-call', (data) {
      print("dsjcldksmclsdkcmlfvkm ${data}");

      setState(() {
        _roomId = data['roomId'];
        _callState = CallState.ringing;
      });
    });

    socket.on('offer', (data) => _onOffer(data));
    socket.on('answer', (data) => _onAnswer(data));
    socket.on('ice-candidate', (data) => _onCandidate(data));
    socket.on('user-disconnected', (_) => _endCall());
  }

  Future<void> _startMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true});
  }

  Future<void> _createCall() async {
    await _startMedia();
    socket.emit('create-room');
  }

  Future<void> _joinCall(String roomId) async {
    await _startMedia();
    socket.emit('join-room', {'roomId': roomId});
  }

  void _listenForUserJoined() {
    socket.on('user-joined', (_) => _createPeerConnection(_roomId!));
  }

  Future<void> _createPeerConnection(String roomId) async {
    _peerConnection = await createPeerConnection(_config);
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate != null) {
        socket.emit('ice-candidate', {'roomId': roomId, 'candidate': candidate.toMap()});
      }
    };

    _peerConnection?.onTrack = (event) {};

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    socket.emit('offer', {'roomId': roomId, 'offer': offer.toMap()});

    _startTimer();
    setState(() => _callState = CallState.connected);
  }

  Future<void> _onOffer(data) async {
    await _startMedia();
    _peerConnection = await createPeerConnection(_config);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (event) {};

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate != null) {
        socket.emit('ice-candidate', {'roomId': _roomId, 'candidate': candidate.toMap()});
      }
    };

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
    );
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    socket.emit('answer', {'roomId': _roomId, 'answer': answer.toMap()});

    _startTimer();
    setState(() => _callState = CallState.connected);
  }

  Future<void> _onAnswer(data) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
    );
    setState(() => _callState = CallState.connected);
  }

  Future<void> _onCandidate(data) async {
    final candidate = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );
    await _peerConnection?.addCandidate(candidate);
  }

  void _toggleMute() {
    if (_localStream == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _localStream?.getAudioTracks()[0].enabled = !_isMuted;
    });
  }

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      final diff = DateTime.now().difference(_startTime).inSeconds;
      final minutes = (diff ~/ 60).toString().padLeft(2, '0');
      final seconds = (diff % 60).toString().padLeft(2, '0');
      setState(() {
        _callDuration = '$minutes:$seconds';
      });
    });
  }

  void _endCall() {
    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;

    _timer?.cancel();
    _callDuration = "00:00";
    _callState = CallState.idle;
    socket.disconnect();

    setState(() {});
  }

  void _acceptIncomingCall() async {
    if (_roomId != null) {
      await _joinCall(_roomId!);
    }
  }

  void _rejectCall() {
    _endCall();
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    switch (_callState) {
      case CallState.idle:
        statusText = "Idle";
        break;
      case CallState.ringing:
        statusText = "Incoming Call...";
        break;
      case CallState.outgoing:
        statusText = "Calling...";
        break;
      case CallState.connected:
        statusText = "Connected";
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text("Audio Call")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Call Status: $statusText"),
            SizedBox(height: 10),
            Text("Call Duration: $_callDuration"),
            SizedBox(height: 20),

            if (_callState == CallState.idle) ...[
              ElevatedButton(onPressed: _createCall, child: Text("Create Call")),
              SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () => _joinCall("ROOM_ID"), child: Text("Join Call")),
            ],

            if (_callState == CallState.ringing) ...[
              ElevatedButton(onPressed: _acceptIncomingCall, child: Text("Accept")),
              ElevatedButton(onPressed: _rejectCall, child: Text("Reject")),
            ],

            if (_callState == CallState.connected) ...[
              ElevatedButton(
                  onPressed: _toggleMute,
                  child: Text(_isMuted ? "Unmute" : "Mute")),
              ElevatedButton(onPressed: _endCall, child: Text("End Call")),
            ],
          ],
        ),
      ),
    );
  }
}

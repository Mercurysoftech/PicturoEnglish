import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/classes/services/native_foreground_service.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';
import 'package:picturo_app/providers/audiosettingsprovider.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:phone_state/phone_state.dart'; // ADD THIS

import '../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';

class VoiceCallScreen extends StatefulWidget {
  final int callerId;
  final String callerName;
  final String? callerImage;
  final bool isIncoming;

  const VoiceCallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callerImage,
    this.isIncoming = false,
  });

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with WidgetsBindingObserver {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isKeypadVisible = false;
  bool showCallControls = true;
  late MediaStream _localStream;
  late RTCPeerConnection _peerConnection;
  Timer? _durationUpdateTimer;
  final NativeForegroundService _foregroundService = NativeForegroundService();

  // NEW: Phone state tracking
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  bool _wasAutoMutedBySystemCall = false;
  bool _wasMutedBeforeSystemCall = false;
  bool _hasShownLowTimeAlert = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!context.read<CallSocketHandleCubit>().isLiveCallActive) {
      context.read<CallSocketHandleCubit>().resetCubit();
      context.read<CallTimerCubit>().resetTimer();
      context.read<CallSocketHandleCubit>().acceptCall(widget.callerId);
    }

    context.read<CallTimerCubit>().startTimer();

    _startDurationUpdateTimer();
    _initPhoneStateListener(); // NEW: Initialize phone state listener
  }

  @override
  void dispose() {
    _durationUpdateTimer?.cancel();
    _phoneStateSubscription?.cancel(); // NEW: Cancel phone state listener
    WidgetsBinding.instance.removeObserver(this);

    if (!context.read<CallSocketHandleCubit>().isLiveCallActive) {
      context.read<CallSocketHandleCubit>().handleCallNotConnected();
    }

    super.dispose();
  }

  // NEW: Initialize phone state listener
  void _initPhoneStateListener() async {
    try {
      _phoneStateSubscription = PhoneState.stream.listen((PhoneState status) {
        print("📱 Phone state changed: ${status.status}");
        _handlePhoneStateChange(status);
      }, onError: (error) {
        print("⚠️ Phone state error: $error");
        // Permission might not be granted or feature not available
      });
    } catch (e) {
      print("⚠️ Failed to initialize phone state listener: $e");
      // Handle permission or initialization errors
    }
  }

  void _showLowTimeAlertDialog(LowTimeAlert alert) {
    if (_hasShownLowTimeAlert) return; // Prevent multiple dialogs

    _hasShownLowTimeAlert = true;

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orange[50],
          icon: Icon(Icons.timer, color: Colors.orange, size: 40),
          title: Text(
            'Low Call Time Alert',
            style: TextStyle(
              color: Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            alert.message,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _hasShownLowTimeAlert = false;
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      // Reset the flag when dialog is closed
      _hasShownLowTimeAlert = false;
    });
  }

  // NEW: Handle system call state changes
  void _handlePhoneStateChange(PhoneState phoneState) {
    final callCubit = context.read<CallSocketHandleCubit>();
    final audioSettings = context.read<AudioSettingsProvider>();

    switch (phoneState.status) {
      case PhoneStateStatus.CALL_INCOMING:
        // System call is just ringing - don't do anything yet
        print("📞 System call ringing - waiting for answer");
        break;

      case PhoneStateStatus.CALL_STARTED:
        // System call CONNECTED - now mute everything
        print("📞 System call CONNECTED - muting both sides");

        // Store current mute state before auto-muting
        _wasMutedBeforeSystemCall = audioSettings.isMuted;
        _wasAutoMutedBySystemCall = true;

        // 1. Mute your microphone (so they don't hear you)
        if (!audioSettings.isMuted) {
          audioSettings.setMute(true);
          callCubit.muteACall(true);
        }

        // 2. Mute remote audio (so you don't hear them)
        _muteRemoteAudio(true);

        // 3. DON'T send hold signal - keep connection alive
        // We're just muting audio, not putting call on hold

        // 4. Pause call timer (optional - since no one is talking)
        context.read<CallTimerCubit>().pauseTimer();
        break;

      case PhoneStateStatus.CALL_ENDED:
        // System call ended
        print("📞 System call ended - restoring WebRTC audio");

        if (_wasAutoMutedBySystemCall) {
          // Unmute your microphone if it wasn't manually muted before
          if (!_wasMutedBeforeSystemCall) {
            audioSettings.setMute(false);
            callCubit.muteACall(false);
          }

          // Unmute remote audio
          _muteRemoteAudio(false);

          _wasAutoMutedBySystemCall = false;
        }

        // Resume call timer
        context.read<CallTimerCubit>().resumeTimer();
        break;

      case PhoneStateStatus.NOTHING:
        // No system call activity
        break;
    }
  }

  // NEW: Method to mute/unmute remote audio
  void _muteRemoteAudio(bool mute) {
    final callCubit = context.read<CallSocketHandleCubit>();

    // Mute all remote renderers
    callCubit.remoteRenderers.forEach((key, renderer) {
      if (renderer.srcObject != null) {
        final audioTracks = renderer.srcObject!.getAudioTracks();
        for (var track in audioTracks) {
          track.enabled = !mute;
        }
      }
    });

    print("🔇 Remote audio ${mute ? 'MUTED' : 'UNMUTED'}");
  }

  void _startDurationUpdateTimer() {
    _durationUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final timerState = context.read<CallTimerCubit>().state;
      final duration = formatDuration(timerState.duration);
      _foregroundService.updateCallDuration(duration);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App went to background
        break;
      case AppLifecycleState.resumed:
        // App came to foreground
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // Clean up when app is being closed
        _durationUpdateTimer?.cancel();
        break;
      default:
        break;
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _toggleMute() {
    final audioSettings = context.read<AudioSettingsProvider>();
    audioSettings.toggleMute();

    // also update WebRTC mute/unmute:
    context.read<CallSocketHandleCubit>().muteACall(audioSettings.isMuted);
  }

  void _toggleSpeaker() async {
    final audioSettings = context.read<AudioSettingsProvider>();
    await Helper.setSpeakerphoneOn(!audioSettings.isSpeakerOn);
    audioSettings.toggleSpeaker();
  }

  @override
  Widget build(BuildContext context) {
    final audioSettings = context.watch<AudioSettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
        builder: (context, state) {
          if (state.lowTimeAlert != null && !_hasShownLowTimeAlert) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showLowTimeAlertDialog(state.lowTimeAlert!);
            });
          }
          
          if (state is CallErrorState) {
            Fluttertoast.showToast(
              msg: state.message,
              backgroundColor: Colors.red,
              toastLength: Toast.LENGTH_LONG,
            );
          }
          if (state is CallRejected) {
            context.read<CallTimerCubit>().stopTimer(
                  receiverId: widget.callerId.toString(),
                  callType: "audio",
                  status: "completed",
                );

            Future.microtask(() {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Homepage()),
                (route) => false,
              );
              context.read<CallSocketHandleCubit>().resetCubit();
            });
          } else if (state is CallOnHold) {
            context.read<CallTimerCubit>().pauseTimer();
          } else if (state is CallResumed) {
            context.read<CallTimerCubit>().resumeTimer();
          }

          return Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.black,
                    ],
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  SizedBox(height: 60),

                  // Caller info
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage('assets/avatar_1.png'),
                      ),
                      SizedBox(height: 20),
                      Text(
                        widget.callerName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      BlocBuilder<CallTimerCubit, CallTimerState>(
                        builder: (context, timerState) {
                          return Text(
                                formatDuration(timerState.duration),
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          );
                        },
                      ),
                    ],
                  ),

                  Spacer(),
                  if (showCallControls) ...[
                    if (isKeypadVisible) _buildKeypad(),
                    if (!isKeypadVisible) _buildCallControls(context),
                  ],
                ],
              ),

              // Close button
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Homepage()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCallControls(BuildContext context) {
    final audioSettings = context.watch<AudioSettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: audioSettings.isMuted ? Icons.mic_off : Icons.mic,
                label: "Mute",
                isActive: audioSettings.isMuted,
                onPressed: _toggleMute,
              ),
              _buildControlButton(
                icon: audioSettings.isSpeakerOn
                    ? Icons.volume_up
                    : Icons.volume_off,
                label: "Speaker",
                isActive: audioSettings.isSpeakerOn,
                onPressed: _toggleSpeaker,
              ),
            ],
          ),
          const SizedBox(height: 60),
          GestureDetector(
            onTap: () {
              context.read<CallSocketHandleCubit>().endCall();
              context.read<CallTimerCubit>().resetTimer();
              context.read<AudioSettingsProvider>().reset();
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(15),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildKeypadButton("1", ""),
              _buildKeypadButton("2", "ABC"),
              _buildKeypadButton("3", "DEF"),
              _buildKeypadButton("4", "GHI"),
              _buildKeypadButton("5", "JKL"),
              _buildKeypadButton("6", "MNO"),
              _buildKeypadButton("7", "PQRS"),
              _buildKeypadButton("8", "TUV"),
              _buildKeypadButton("9", "WXYZ"),
              _buildKeypadButton("*", ""),
              _buildKeypadButton("0", "+"),
              _buildKeypadButton("#", ""),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: Icons.arrow_back,
                label: "Back",
                onPressed: () => setState(() => isKeypadVisible = false),
              ),
              _buildControlButton(
                icon: Icons.call,
                label: "Call",
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String number, String letters) {
    return GestureDetector(
      onTap: () {
        print("Pressed: $number");
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

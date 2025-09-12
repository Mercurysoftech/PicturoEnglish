import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';
import 'package:picturo_app/screens/homepage.dart';

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

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isKeypadVisible = false;
  bool showCallControls = true;
  late MediaStream _localStream;
  late RTCPeerConnection _peerConnection;


  @override
  void initState() {
    super.initState();
    context.read<CallSocketHandleCubit>().resetCubit();
    if(!context.read<CallSocketHandleCubit>().isLiveCallActive) {
      context.read<CallTimerCubit>().resetTimer();
    }
    context.read<CallSocketHandleCubit>().acceptCall(widget.callerId);
    context.read<CallTimerCubit>().startTimer();

  }


  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _toggleMute() {
    setState(() {
      isMuted = ! isMuted;
    });
    context.read<CallSocketHandleCubit>().muteACall(isMuted);
  }

  void _toggleSpeaker() async {
    await Helper.setSpeakerphoneOn(!isSpeakerOn);
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
        builder: (context, state) {

          if(state is CallRejected){
            context.read<CallTimerCubit>().stopTimer(
              receiverId: widget.callerId.toString(),
              callType: "audio",
              status: "completed",
            );
            Future.delayed(Duration.zero,(){
                Navigator.pop(context);
              context.read<CallSocketHandleCubit>().resetCubit();
            });
          }else if(state is CallOnHold){
            context.read<CallTimerCubit>().pauseTimer();
          }else if(state is CallResumed){
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
                        backgroundImage:AssetImage('assets/avatar_1.png'),
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
                      // SizedBox(height: 10),
                      SizedBox(height: 10),
                      BlocBuilder<CallTimerCubit, CallTimerState>(
                        builder: (context, timerState) {
                          return Text(
                              (state is CallOnHold)?"Call on Hold":formatDuration(timerState.duration),
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          );
                        },
                      ),
                    ],
                  ),

                  Spacer(),

                  // Call controls
                  if (showCallControls) ...[
                    if (isKeypadVisible) _buildKeypad(),
                    if (!isKeypadVisible) _buildCallControls(),
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
)
,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        children: [
          // First row of controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                label: "Mute",
                isActive: isMuted,
                onPressed: (){
                  _toggleMute();
                },
              ),
              // _buildControlButton(
              //   icon: Icons.dialpad,
              //   label: "Keypad",
              //   onPressed: () => setState(() => isKeypadVisible = true),
              // ),
              _buildControlButton(
                icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                label: "Speaker",
                isActive: isSpeakerOn,
                onPressed: () {
                  _toggleSpeaker();
                },
              ),
            ],
          ),
          SizedBox(height: 40),
          // Second row of controls
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     _buildControlButton(
          //       icon: Icons.person_add,
          //       label: "Add call",
          //       onPressed: () {},
          //     ),
          //     _buildControlButton(
          //       icon: Icons.videocam,
          //       label: "Video",
          //       onPressed: () {},
          //     ),
          //     _buildControlButton(
          //       icon: Icons.record_voice_over,
          //       label: "Record",
          //       onPressed: () {},
          //     ),
          //   ],
          // ),
          SizedBox(height: 60),
          // End call button
          GestureDetector(
            onTap: (){
              context.read<CallSocketHandleCubit>().endCall();
              context.read<CallTimerCubit>().resetTimer();
            },
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
        // Handle keypad press
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

// Example usage:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => VoiceCallScreen(
//       callerName: "John Doe",
//       callerImage: "https://example.com/profile.jpg",
//       isIncoming: false,
//     ),
//   ),
// );
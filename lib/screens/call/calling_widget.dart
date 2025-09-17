import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import '../../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../../cubits/call_log_his_cubit/call_log_cubit.dart';
import '../../responses/friends_response.dart';
import '../../services/api_service.dart';
import '../voicecallscreen.dart';

class CallingScreen extends StatefulWidget {
  final String callerName;
  final int currentUserId;
  final int? avatarUrl;
  final int? friendId;

  const CallingScreen({
    super.key,
    required this.callerName,
    required this.currentUserId,
    required this.avatarUrl,
    required this.friendId,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
   bool _isNavigating = false;

   // 🎵 audio players
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _hangupPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    await _ringtonePlayer.play(
      AssetSource("audio/phone-ringing-382734.mp3"),
    );
  }

  Future<void> _stopRingtone() async {
    await _ringtonePlayer.stop();
  }


   @override
  void dispose() {
    _ringtonePlayer.dispose();
    _hangupPlayer.dispose();
    super.dispose(); 
  }

  Future<String> _getAvatarUrl(int? avatarId) async {
    if (avatarId == null || avatarId == 0) {
      return ''; 
    }

    try {
      final apiService = await ApiService.create();
      final avatarResponse = await apiService.fetchAvatars();
      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );
      return 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
    } catch (e) {
      print('Error fetching avatar URL: $e');
      return ''; // Return empty string on error
    }
  }


   Widget _buildUserAvatar(int? avatarId) {
    // Handle null or default avatar case
    if (avatarId == null || avatarId == 0) {
      return const CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFF49329A),
        backgroundImage: AssetImage('assets/avatar2.png'),
      );
    }

    return FutureBuilder<String>(
      future: _getAvatarUrl(avatarId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: AssetImage('assets/avatar2.png'),
          );
        }

        return CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(snapshot.data!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 80;

    final int safeFriendId = widget.friendId ?? 0; 

    return Scaffold(
      body: BlocListener<CallSocketHandleCubit, CallSocketHandleState>(
        listener: (context, state) async {
          if (_isNavigating) return;

          if (state is CallRejected) {
            await _stopRingtone();
            _isNavigating = true;
            Navigator.of(context).pop();
            context.read<CallSocketHandleCubit>().resetCubit();
          } else if (state is CallAccepted) {
            await _stopRingtone();
            _isNavigating = true;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                  callerId: safeFriendId,
                  callerName: widget.callerName,
                  callerImage: '',
                  isIncoming: false,
                ),
              ),
            ).then((_) {
              if (mounted) {
                context.read<CallSocketHandleCubit>().resetCubit();
              }
            });
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D2671), Color(0xFFC33764)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _buildUserAvatar(widget.avatarUrl),
                  ),
                  const SizedBox(height: 30),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.callerName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Calling...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  GestureDetector(
                    onTap: () async {
                      try {
                         await _stopRingtone(); // stop ringing
                        if (await Vibration.hasVibrator() ?? false) {
    Vibration.vibrate(duration: 500); // 0.5 second vibration
  }

                        await context.read<CallSocketHandleCubit>().endCall();
                        if (widget.friendId != null) {
      await context
          .read<CallSocketHandleCubit>()
          .sendCallEndNotification(widget.friendId!);
    }
                        await context.read<CallLogCubit>().postCallLog(
                          receiverId: safeFriendId.toString(),
                          callType: "audio",
                          status: "inCompleted",
                          duration: 1,
                        );
                        if (mounted) Navigator.of(context).pop();
                      } catch (e) {
                        print('Error ending call: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error ending call: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.deepOrange],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
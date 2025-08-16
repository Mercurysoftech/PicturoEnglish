import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  void initState() {
    super.initState();

  }

  Future<String> _getAvatarUrl(int avatarId) async {
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
      throw e;
    }
  }

  Widget _buildUserAvatar(int avatarId) {
    if (avatarId == 0) {
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
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: AssetImage('assets/avatar2.png'),
          );
        } else {
          return CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(snapshot.data!),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 80;

    return Scaffold(
      body: BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
        builder: (context, state) {
          print("skdcmklsdcmlskdc ${state.runtimeType}");
          if (state is CallRejected) {
            Future.delayed(Duration.zero, () {
              // if (context.mounted && Navigator.canPop(context)) {
              //
              //
              // }
              Navigator.pop(context);
              context.read<CallSocketHandleCubit>().resetCubit();
            });
          } else if (state is CallAccepted) {
            Future.delayed(Duration.zero, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VoiceCallScreen(
                    callerId: widget.friendId??0,
                    callerName: widget.callerName,
                    callerImage: '',
                    isIncoming: false,
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<CallSocketHandleCubit>().resetCubit();
                }
              });
            });
          }

          return Container(
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
                    // Avatar with shadow
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
                      child: widget.avatarUrl == null
                          ?  CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: AssetImage('assets/avatar2.png'),
                      )
                          : _buildUserAvatar(widget.avatarUrl!),
                    ),
                    const SizedBox(height: 30),

                    // Blurred name card
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

                    // End Call Button
                    GestureDetector(
                      onTap: () async {
                        context.read<CallSocketHandleCubit>().endCall();

                        await context.read<CallLogCubit>().postCallLog(
                          receiverId: widget.friendId.toString(),
                          callType: "audio",
                          status: "inCompleted",
                          duration: 1,
                        );

                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
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
          );
        },
      ),
    );
  }
}

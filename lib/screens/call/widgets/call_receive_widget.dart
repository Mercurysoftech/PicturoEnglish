import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';

class CallAcceptScreen extends StatefulWidget {
  final String callerName;
  final int callerId;
  final int? avatarUrl;

  const CallAcceptScreen({
    super.key,
    required this.callerName,
    required this.callerId,
    this.avatarUrl,
  });

  @override
  State<CallAcceptScreen> createState() => _CallAcceptScreenState();
}

class _CallAcceptScreenState extends State<CallAcceptScreen> {
  bool _isNavigating = false;

  Widget _buildAvatar(int? avatarId) {
    if (avatarId == null || avatarId == 0) {
      return const CircleAvatar(
        radius: 40,
        backgroundImage: AssetImage('assets/avatar2.png'),
      );
    }
    return CircleAvatar(
      radius: 40,
      backgroundImage: NetworkImage(
        "http://picturoenglish.com/admin/$avatarId", // Adjust if avatarUrl is a path
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<CallSocketHandleCubit, CallSocketHandleState>(
        listener: (context, state) {
          print('Sate: $state and isNaviagtion: $_isNavigating');
          if (_isNavigating) return;

          if (state is CallRejected) {
            Future.delayed(Duration.zero, () {
              _isNavigating = true;
            //Navigator.of(context).pop();
            context.read<CallSocketHandleCubit>().resetCubit();
            });
          } else if (state is CallAccepted) {
            _isNavigating = true;
            Navigator.of(context)
                .pushReplacement(
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                  callerId: widget.callerId,
                  callerName: widget.callerName,
                  callerImage: '',
                  isIncoming: true,
                ),
              ),
            )
                .then((_) {
              if (mounted) {
                context.read<CallSocketHandleCubit>().resetCubit();
              }
            });
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(widget.avatarUrl),
                const SizedBox(height: 20),
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
                  "Incoming Call...",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline button
                    GestureDetector(
                      onTap: () async {
                        context.read<CallSocketHandleCubit>().endCall();
                        //if (mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.deepOrange],
                          ),
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () async {
                        context
                            .read<CallSocketHandleCubit>()
                            .acceptCall(widget.callerId);
                        // navigation will be handled by BlocListener
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.teal],
                          ),
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

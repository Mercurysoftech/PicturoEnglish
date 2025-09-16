import 'package:flutter_bloc/flutter_bloc.dart';

class CallControlsState {
  final bool isMuted;
  final bool isSpeakerOn;
  const CallControlsState({
    this.isMuted = false,
    this.isSpeakerOn = false,
  });

  CallControlsState copyWith({bool? isMuted, bool? isSpeakerOn}) {
    return CallControlsState(
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }
}
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

class CallControlsCubit extends Cubit<CallControlsState> {
  CallControlsCubit() : super(const CallControlsState());

  void toggleMute() => emit(state.copyWith(isMuted: !state.isMuted));
  void toggleSpeaker() => emit(state.copyWith(isSpeakerOn: !state.isSpeakerOn));
  void setMute(bool v) => emit(state.copyWith(isMuted: v));
  void setSpeaker(bool v) => emit(state.copyWith(isSpeakerOn: v));
}

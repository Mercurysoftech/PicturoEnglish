part of 'call_duration_handle_cubit.dart';

class CallTimerState extends Equatable {
  final Duration duration;

  const CallTimerState({this.duration = Duration.zero});

  CallTimerState copyWith({Duration? duration}) {
    return CallTimerState(duration: duration ?? this.duration);
  }

  @override
  List<Object?> get props => [duration];
}
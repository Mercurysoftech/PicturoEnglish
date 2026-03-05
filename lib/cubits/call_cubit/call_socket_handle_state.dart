part of 'call_socket_handle_cubit.dart';

enum CallStatus {
  initial,
  accepted,
  rejected,
  onHold,
  resumed,
}

class CallSocketHandleState extends Equatable {
  final CallStatus status;
  final bool isMuted;
  final bool isSpeakerOn;
  final int remainingMinutes;
  final LowTimeAlert? lowTimeAlert;

  const CallSocketHandleState({
    this.status = CallStatus.initial,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.remainingMinutes = 0,
    this.lowTimeAlert,
  });

  CallSocketHandleState copyWith({
    CallStatus? status,
    bool? isMuted,
    bool? isSpeakerOn,
    int? remainingMinutes,
    LowTimeAlert? lowTimeAlert,
  }) {
    return CallSocketHandleState(
      status: status ?? this.status,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      lowTimeAlert: lowTimeAlert ?? this.lowTimeAlert,
    );
  }

  @override
  List<Object?> get props => [status, isMuted, isSpeakerOn, remainingMinutes,lowTimeAlert];
}

final class CallSocketHandleInitial extends CallSocketHandleState {
  const CallSocketHandleInitial() : super();
  @override
  List<Object> get props => [];
}

final class CallRejected extends CallSocketHandleState {
  @override
  List<Object> get props => [];
}

final class CallOnHold extends CallSocketHandleState {
  @override
  List<Object> get props => [];
}

final class CallResumed extends CallSocketHandleState {
  @override
  List<Object> get props => [];
}

final class CallAccepted extends CallSocketHandleState {
  @override
  List<Object> get props => [];
}

class CallErrorState extends CallSocketHandleState {
  final String message;
  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message, ...super.props];
}

class LowTimeAlert extends Equatable {
  final int remaining;
  final int threshold;
  final String message;

  const LowTimeAlert({
    required this.remaining,
    required this.threshold,
    required this.message,
  });

  @override
  List<Object?> get props => [remaining, threshold, message];
}

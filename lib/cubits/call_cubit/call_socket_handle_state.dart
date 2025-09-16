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

  const CallSocketHandleState({
    this.status = CallStatus.initial,
  });

  @override
  List<Object?> get props => [status];
}

final class CallSocketHandleInitial extends CallSocketHandleState {
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
  CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
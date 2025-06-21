part of 'call_socket_handle_cubit.dart';

sealed class CallSocketHandleState extends Equatable {
  const CallSocketHandleState();
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

part of 'call_log_cubit.dart';


abstract class CallLogState extends Equatable {
  const CallLogState();

  @override
  List<Object> get props => [];
}

class CallLogInitial extends CallLogState {}

class CallLogLoading extends CallLogState {}

class CallLogLoaded extends CallLogState {
  final List<CallLog> callLogs;

  const CallLogLoaded(this.callLogs);

  @override
  List<Object> get props => [callLogs];
}

class CallLogError extends CallLogState {
  final String message;

  const CallLogError(this.message);

  @override
  List<Object> get props => [message];
}

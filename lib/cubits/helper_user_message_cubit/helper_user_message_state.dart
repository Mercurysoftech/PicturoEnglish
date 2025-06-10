part of 'helper_user_message_cubit.dart';

sealed class HelperUserMessageState extends Equatable {
  const HelperUserMessageState();
}

final class HelperUserMessageInitial extends HelperUserMessageState {
  @override
  List<Object> get props => [];
}
final class HelperUserMessageLoading extends HelperUserMessageState {
  @override
  List<Object> get props => [];
}
final class HelperUserMessageLoaded extends HelperUserMessageState {
  @override
  List<Object> get props => [];
}
final class HelperUserMessageFailed extends HelperUserMessageState {
  @override
  List<Object> get props => [];
}

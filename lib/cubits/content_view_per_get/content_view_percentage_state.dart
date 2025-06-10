part of 'content_view_percentage_cubit.dart';

abstract class ProgressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final double progress;

  ProgressLoaded(this.progress);

  @override
  List<Object?> get props => [progress];
}

class ProgressFailed extends ProgressState {
  final String message;

  ProgressFailed(this.message);

  @override
  List<Object?> get props => [message];
}

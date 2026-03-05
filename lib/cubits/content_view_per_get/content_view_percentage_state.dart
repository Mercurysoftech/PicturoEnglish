// content_view_percentage_state.dart
part of 'content_view_percentage_cubit.dart';

abstract class ProgressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final double progress;
  final bool shouldShowSubscriptionDialog;
  final bool isFreehitUser;
  final bool isSubscribePlan;
  final int actualProgress;
  final int allowedProgress;

  ProgressLoaded(
    this.progress, {
    this.shouldShowSubscriptionDialog = false,
    this.isFreehitUser = false,
    this.isSubscribePlan = false,
    this.actualProgress = 0,
    this.allowedProgress = 0,
  });

  @override
  List<Object?> get props => [
        progress,
        shouldShowSubscriptionDialog,
        isFreehitUser,
        isSubscribePlan,
        actualProgress,
        allowedProgress,
      ];
}

class ProgressFailed extends ProgressState {
  final String message;

  ProgressFailed(this.message);

  @override
  List<Object?> get props => [message];
}
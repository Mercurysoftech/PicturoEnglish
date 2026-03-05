// quest_game_qtn_list_state.dart
part of 'quest_game_qtn_list_cubit.dart';

abstract class GrammarQuestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GrammarQuestLoading extends GrammarQuestState {}

class GrammarQuestLoaded extends GrammarQuestState {
  final List<GrammarQuestion> questions;
  final bool shouldShowSubscriptionDialog;
  final bool isFreeHitUser;
  final bool isSubscribePlan;
  final int progressPercentage;
  final int maxAllowedPercentage;

  GrammarQuestLoaded(
    this.questions, {
    this.shouldShowSubscriptionDialog = false,
    this.isFreeHitUser = false,
    this.isSubscribePlan = false,
    this.progressPercentage = 0,
    this.maxAllowedPercentage = 0,
  });

  @override
  List<Object?> get props => [
        questions,
        shouldShowSubscriptionDialog,
        isFreeHitUser,
        isSubscribePlan,
        progressPercentage,
        maxAllowedPercentage,
      ];
}

class GrammarQuestFailed extends GrammarQuestState {
  final String message;

  GrammarQuestFailed(this.message);

  @override
  List<Object?> get props => [message];
}
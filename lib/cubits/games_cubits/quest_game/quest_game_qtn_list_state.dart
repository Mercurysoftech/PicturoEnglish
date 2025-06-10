part of 'quest_game_qtn_list_cubit.dart';

abstract class GrammarQuestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GrammarQuestLoading extends GrammarQuestState {}

class GrammarQuestLoaded extends GrammarQuestState {
  final List<GrammarQuestion> questions;
  final int level;

  GrammarQuestLoaded(this.questions,this.level);

  @override
  List<Object?> get props => [questions,level];
}

class GrammarQuestFailed extends GrammarQuestState {
  final String message;

  GrammarQuestFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class GrammarQuestion {
  final int id;
  final String gameQus;

  GrammarQuestion({required this.id, required this.gameQus});

  factory GrammarQuestion.fromJson(Map<String, dynamic> json) {
    return GrammarQuestion(
      id: json['id'],
      gameQus: json['game_qus'],
    );
  }
}

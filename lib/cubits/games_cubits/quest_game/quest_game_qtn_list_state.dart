part of 'quest_game_qtn_list_cubit.dart';

abstract class GrammarQuestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GrammarQuestLoading extends GrammarQuestState {}

class GrammarQuestLoaded extends GrammarQuestState {
  final List<GrammarQuestion> questions;


  GrammarQuestLoaded(this.questions,);

  @override
  List<Object?> get props => [questions];
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
  final String image_path;
  final int level;
  final bool completed;

  GrammarQuestion({required this.id, required this.gameQus,required this.image_path,required  this.level,required this.completed});

  factory GrammarQuestion.fromJson(Map<String, dynamic> json) {
    return GrammarQuestion(
      level: json["level"]??0,
      completed: json['completed']??false,
      image_path: json['image_path']??'',
      id: json['id']??0,
      gameQus: json['sentence']??'',
    );
  }
}

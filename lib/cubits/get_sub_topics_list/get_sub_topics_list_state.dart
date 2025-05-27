part of 'get_sub_topics_list_cubit.dart';


abstract class SubtopicState extends Equatable {
  const SubtopicState();

  @override
  List<Object?> get props => [];
}

class SubtopicInitial extends SubtopicState {}

class SubtopicLoading extends SubtopicState {}

class SubtopicLoaded extends SubtopicState {
  final List<Question> questions;

  const SubtopicLoaded(this.questions);

  @override
  List<Object?> get props => [questions];
}

class SubtopicError extends SubtopicState {
  final String message;

  const SubtopicError(this.message);

  @override
  List<Object?> get props => [message];
}

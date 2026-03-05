// get_sub_topics_list_state.dart
part of 'get_sub_topics_list_cubit.dart';

abstract class SubtopicState extends Equatable {
  const SubtopicState();
  
  @override
  List<Object?> get props => [];
}

class SubtopicInitial extends SubtopicState {}

class SubtopicLoading extends SubtopicState {}

// New state for progressive loading
class SubtopicProgressiveLoading extends SubtopicState {
  final List<Question> loadedQuestions;
  final int totalCount;
  
  const SubtopicProgressiveLoading({
    required this.loadedQuestions,
    required this.totalCount,
  });
  
  @override
  List<Object?> get props => [loadedQuestions, totalCount];
}

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
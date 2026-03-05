part of 'get_topic_list_cubit.dart';

class TopicState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Initial state - no loading shown
class TopicInitial extends TopicState {}

class TopicLoading extends TopicState {}

class TopicLoaded extends TopicState {
  final List<Map<String, dynamic>> topics;

  TopicLoaded(this.topics);

  @override
  List<Object?> get props => [topics];
}

class TopicError extends TopicState {
  final String message;

  TopicError(this.message);

  @override
  List<Object?> get props => [message];
}
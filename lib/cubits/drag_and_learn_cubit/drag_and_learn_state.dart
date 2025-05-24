part of 'drag_and_learn_cubit.dart';


abstract class DragLearnState extends Equatable {
  @override
  List<Object> get props => [];
}

class DragLearnLoading extends DragLearnState {}

class DragLearnLoaded extends DragLearnState {
  final DragAndLearnLevelModel data;

  DragLearnLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class DragLearnFailed extends DragLearnState {
  final String error;

  DragLearnFailed(this.error);

  @override
  List<Object> get props => [error];
}
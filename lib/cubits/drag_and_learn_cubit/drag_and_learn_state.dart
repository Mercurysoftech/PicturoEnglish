part of 'drag_and_learn_cubit.dart';


abstract class DragLearnState extends Equatable {
  @override
  List<Object> get props => [];
}

class DragLearnLoading extends DragLearnState {}

class DragLearnLoaded extends DragLearnState {
  final DragAndLearnLevelModel data;
  final int level;

  DragLearnLoaded(this.data,this.level);

  @override
  List<Object> get props => [data,level];
}

class DragLearnFailed extends DragLearnState {
  final String error;

  DragLearnFailed(this.error);

  @override
  List<Object> get props => [error];
}
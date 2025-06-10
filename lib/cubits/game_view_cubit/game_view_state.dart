part of 'game_view_cubit.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final List<String> gameNames;

  const GameLoaded({required this.gameNames});

  @override
  List<Object?> get props => [gameNames];
}

class GameError extends GameState {
  final String errorMessage;

  const GameError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

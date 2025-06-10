import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responses/games_response.dart';
import '../../services/api_service.dart';

part 'game_view_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(GameInitial());

  Future<void> fetchGamesAndUpdateGrid() async {
    (state is GameInitial)?emit(GameLoading()):null;
    try {
      final apiService = await ApiService.create();
      final GamesResponse gamesResponse = await apiService.fetchGames();
       SharedPreferences pref =await SharedPreferences.getInstance();

      final List<String> gameNames = gamesResponse.data
          .map((game) => game.gameName)
          .toList();

      emit(GameLoaded(gameNames: gameNames));
    } catch (e) {
      emit(GameError("Error fetching games: $e"));
    }
  }
}

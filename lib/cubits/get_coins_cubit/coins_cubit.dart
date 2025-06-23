import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'coins_state.dart';


class PrefsKeys {
  static const String coin = 'coin';
  static const String isFirstTime = 'isFirstTime';
}

class CoinCubit extends Cubit<CoinState> {
  CoinCubit() : super(CoinInitial());

  Future<void> loadCoins() async {
    emit(CoinLoading());
    final prefs = await SharedPreferences.getInstance();
    int coins = prefs.getInt(PrefsKeys.coin) ?? 0;
    emit(CoinLoaded(coins));
  }

  Future <int> getCoin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PrefsKeys.coin) ?? 0;
  }

  Future<void> setCoin(int coin) async {
    emit(CoinLoading());
    final prefs = await SharedPreferences.getInstance();
    bool isFirst = prefs.getBool(PrefsKeys.isFirstTime) ?? false;
    // if (isFirst) {
      await prefs.setInt(PrefsKeys.coin, coin);
    // }
    await prefs.setBool(PrefsKeys.isFirstTime, false);

    // int updatedCoin = prefs.getInt(PrefsKeys.coin) ?? 0;
    loadCoins();
  }

  Future<void> useCoin(int amount) async {
    emit(CoinLoading());
    final prefs = await SharedPreferences.getInstance();
    int currentCoins = prefs.getInt(PrefsKeys.coin) ?? 0;

    if (currentCoins >= amount) {
      int updatedCoins = currentCoins - amount;
      await prefs.setInt(PrefsKeys.coin, updatedCoins);
      emit(CoinLoaded(updatedCoins));
    } else {
      emit(const CoinError('Not enough coins.'));
      emit(CoinLoaded(currentCoins));
    }
  }
}
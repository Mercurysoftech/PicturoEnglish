





import 'package:shared_preferences/shared_preferences.dart';

extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) =>
    word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}




class SharedPrefsService {

  Future<void> setCoin(int coin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirst= prefs.getBool(PrefsKeys.isFirstTime)??false;
    if(isFirst) {
      await prefs.setInt(PrefsKeys.coin, coin);
    }
  }

  Future <int> getCoin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PrefsKeys.coin) ?? 0;
  }


  Future<bool> useCoin(int amount) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCoins = prefs.getInt(PrefsKeys.coin) ?? 0;

    if (currentCoins >= amount) {
      int updatedCoins = currentCoins - amount;
      await prefs.setInt(PrefsKeys.coin, updatedCoins);
      return true;
    } else {
      return false;
    }
  }
}



class PrefsKeys{

  static const String coin ='coin';
  static const String isFirstTime ='isFirstTime';
}
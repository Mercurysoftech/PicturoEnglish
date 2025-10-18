import 'package:flutter/material.dart';

class RemainingMinutesProvider with ChangeNotifier {
  int _remainingMinutes = 0;
  
  int get remainingMinutes => _remainingMinutes;
  
  void updateRemainingMinutes(int minutes) {
    if (_remainingMinutes != minutes) {
      _remainingMinutes = minutes;
      notifyListeners();
    }
  }
  
  void reset() {
    _remainingMinutes = 0;
    notifyListeners();
  }
}
// unread_count_provider.dart
import 'package:flutter/foundation.dart';
import 'package:picturo_app/services/api_service.dart';

class UnreadCountProvider with ChangeNotifier {
  int _totalUnreadCount = 0;

  int get totalUnreadCount => _totalUnreadCount;

  void updateTotalUnreadCount(int count) {
    _totalUnreadCount = count;
    notifyListeners();
  }

  void incrementUnreadCount() {
    _totalUnreadCount++;
    notifyListeners();
  }

  void decrementUnreadCount() {
    if (_totalUnreadCount > 0) {
      _totalUnreadCount--;
      notifyListeners();
    }
  }

  void resetUnreadCount() {
    _totalUnreadCount = 0;
    notifyListeners();
  }

}
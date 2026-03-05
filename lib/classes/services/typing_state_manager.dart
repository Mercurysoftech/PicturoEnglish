// typing_state_manager.dart
import 'package:flutter/foundation.dart';

class TypingStateManager with ChangeNotifier {
  final Map<String, bool> _typingUsers = {};

  bool isUserTyping(String userId) {
    return _typingUsers[userId] ?? false;
  }

  void setTypingStatus(String userId, bool isTyping) {
    _typingUsers[userId] = isTyping;
    notifyListeners();
  }

  void clearTypingStatus(String userId) {
    _typingUsers.remove(userId);
    notifyListeners();
  }

  void clearAll() {
    _typingUsers.clear();
    notifyListeners();
  }
}
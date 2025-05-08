import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userId = '';

  String get userId => _userId;

  void setUserId(String id) {
    _userId = id;
    print('user_id:$_userId');
    notifyListeners(); // Notify listeners about the change
  }
  
}

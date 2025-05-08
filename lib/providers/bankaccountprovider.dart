import 'package:flutter/material.dart';

class BankAccountProvider extends ChangeNotifier {
  Map<String, dynamic>? _bankAccountDetails;

  Map<String, dynamic>? get bankAccountDetails => _bankAccountDetails;

  void setBankAccountDetails(Map<String, dynamic> details) {
    _bankAccountDetails = details;
    notifyListeners(); // Notify listeners to rebuild UI when data changes
  }
}
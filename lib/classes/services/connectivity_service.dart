// connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final Connectivity _connectivity = Connectivity();

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
  // Check initial connectivity (now returns a list)
  var connectivityResults = await _connectivity.checkConnectivity();
  _updateConnectionStatus(connectivityResults);

  // Listen for connectivity changes
  _connectivity.onConnectivityChanged.listen((results) {
    _updateConnectionStatus(results);
  });
}

void _updateConnectionStatus(List<ConnectivityResult> results) {
  // Check if ANY result is "connected"
  bool newStatus = results.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet);

  if (_isOnline != newStatus) {
    _isOnline = newStatus;
    notifyListeners();
  }
}

}
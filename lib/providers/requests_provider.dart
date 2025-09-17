import 'package:flutter/material.dart';
import 'package:picturo_app/responses/chat_requests_response.dart';
import 'package:picturo_app/services/api_service.dart';

class RequestsProvider with ChangeNotifier {
  int _requestsCount = 0;

  int get requestsCount => _requestsCount;

  void setRequestsCount(int count) {
    _requestsCount = count;
    notifyListeners();
  }

  void increment() {
    _requestsCount++;
    notifyListeners();
  }

  void decrement() {
    if (_requestsCount > 0) {
      _requestsCount--;
      notifyListeners();
    }
  }

  Future<void> fetchRequestsCount() async {
    final apiService = await ApiService.create();
    final RequestsResponse response = await apiService.fetchRequests();

    final pending = response.received_requests
        .where((user) => user.status != "accepted" && user.status == "pending") 
        .toList();

    setRequestsCount(pending.length); 
  }
}

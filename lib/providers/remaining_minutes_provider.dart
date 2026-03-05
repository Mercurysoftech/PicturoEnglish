import 'package:flutter/material.dart';

class RemainingMinutesProvider with ChangeNotifier {
  int _remainingMinutes = 0;
  int _allowedSeconds = 600; // Default to free plan (10 min)
  int _planId = 1; // Default to free plan

  int get remainingMinutes => _remainingMinutes;
  int get allowedSeconds => _allowedSeconds;
  int get planId => _planId;

  /// Get allowed minutes (converted from seconds)
  int get allowedMinutes => _allowedSeconds ~/ 60;

  /// Check if user has unlimited calls (24-hour plan)
  bool get hasUnlimitedCalls => _allowedSeconds >= 86400;

  void updateRemainingMinutes(int minutes) {
    if (_remainingMinutes != minutes) {
      _remainingMinutes = minutes;
      notifyListeners();
    }
  }

  /// Update all plan-related data at once
  void updatePlanData({
    required int remainingMinutes,
    int? allowedSeconds,
    int? planId,
  }) {
    bool changed = false;

    if (_remainingMinutes != remainingMinutes) {
      _remainingMinutes = remainingMinutes;
      changed = true;
    }

    if (allowedSeconds != null && _allowedSeconds != allowedSeconds) {
      _allowedSeconds = allowedSeconds;
      changed = true;
    }

    if (planId != null && _planId != planId) {
      _planId = planId;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void reset() {
    _remainingMinutes = 0;
    _allowedSeconds = 600;
    _planId = 1;
    notifyListeners();
  }
}
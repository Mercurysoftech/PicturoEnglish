// services/bot_calls_refresh_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picturo_app/providers/remaining_bot_calls_provider';
import 'package:provider/provider.dart';

class BotCallsRefreshService {
  static Timer? _refreshTimer;

  static void startPeriodicRefresh(BuildContext context, {int intervalMinutes = 2}) {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    
    // Refresh immediately
    _refreshImmediately(context);
    
    // Set up periodic refresh
    _refreshTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      if (context.mounted) {
        _refreshImmediately(context);
      }
    });
  }

  static void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  static void _refreshImmediately(BuildContext context) {
    final provider = context.read<RemainingBotCallsProvider>();
    provider.fetchRemainingBotCalls();
  }

  // Call this when you know values might have changed (after calls, etc.)
  static void refreshOnCallEnd(BuildContext context) {
    if (context.mounted) {
      // Wait a bit for the server to update, then refresh
      Future.delayed(Duration(seconds: 2), () {
        if (context.mounted) {
          _refreshImmediately(context);
        }
      });
    }
  }

  // Call this when app comes to foreground
  static void refreshOnAppResume(BuildContext context) {
    if (context.mounted) {
      _refreshImmediately(context);
    }
  }
}
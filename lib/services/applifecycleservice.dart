// // app_lifecycle_service.dart
// import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

// import 'package:flutter/widgets.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:picturo_app/services/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AppLifecycleService with WidgetsBindingObserver {
//   static final AppLifecycleService _instance = AppLifecycleService._internal();

//   factory AppLifecycleService() => _instance;

//   AppLifecycleService._internal();

//   bool _isInitialized = false;
//   bool _isInCall = false;
//   Function? _onCallEndCallback;

//   Future<void> initialize({Function? onCallEnd}) async {
//     if (_isInitialized) return;

//     WidgetsBinding.instance.addObserver(this);
//     _isInitialized = true;
//     _onCallEndCallback = onCallEnd;

//     // Check if we need to cleanup from previous crash
//     await _cleanupAfterCrash();
//   }

//   void setInCall(bool inCall) {
//     _isInCall = inCall;
//   }

//   Future<void> dispose() async {
//     WidgetsBinding.instance.removeObserver(this);
//     _isInitialized = false;

//     // End call if app is being disposed while in call
//     if (_isInCall) {
//       await _endCall();
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) async {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         // App came to foreground - check if we need to cleanup
//         await _cleanupAfterCrash();
//         break;

//       case AppLifecycleState.inactive:
//       case AppLifecycleState.paused:
//         // App going to background - end call if active
//         if (_isInCall) {
//           await _endCall();
//         }
//         break;

//       case AppLifecycleState.detached:
//         // App being destroyed - ensure call is ended
//         if (_isInCall) {
//           await _endCall();
//         }
//         break;

//       case AppLifecycleState.hidden:
//         break;
//     }
//   }

//   Future<void> _endCall() async {
//     try {
//       if (_onCallEndCallback != null) {
//         await _onCallEndCallback!();
//       }

//       // Also end through CallKit
//       await FlutterCallkitIncoming.endAllCalls();

//       _isInCall = false;

//       // Clear any call state from shared preferences
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('last_active_call');

//       print('✅ Call properly ended during app lifecycle change');
//     } catch (e) {
//       print('❌ Error ending call during lifecycle: $e');
//     }
//   }

//   Future<void> _cleanupAfterCrash() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final hadActiveCall = prefs.getBool('last_active_call') ?? false;

//       if (hadActiveCall) {
//         print('🔄 Cleaning up after possible crash during call');
//         await FlutterCallkitIncoming.endAllCalls();
//         await prefs.remove('last_active_call');

//         // Notify server about call ending due to crash
//         await _notifyServerAboutCrash();
//       }
//     } catch (e) {
//       print('❌ Error during crash cleanup: $e');
//     }
//   }

//   Future<void> _notifyServerAboutCrash() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('user_id');
//       final callTargetId = prefs.getString('last_call_target_id');

//       if (userId != null && callTargetId != null) {
//         // Make API call to notify server about call ending due to crash
//         final apiService = await ApiService.create();
//         await apiService.rejectCall(
//           int.parse(userId),
//           int.parse(callTargetId)
//         );
//       }
//     } catch (e) {
//       print('❌ Error notifying server about crash: $e');
//     }
//   }

//   Future<void> onCallStarted(int targetUserId) async {
//     _isInCall = true;

//     // Store call state in shared preferences for crash recovery
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('last_active_call', true);
//     await prefs.setString('last_call_target_id', targetUserId.toString());
//   }

//   Future<void> onCallEnded() async {
//     _isInCall = false;

//     // Clear call state from shared preferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('last_active_call');
//     await prefs.remove('last_call_target_id');
//   }
// }

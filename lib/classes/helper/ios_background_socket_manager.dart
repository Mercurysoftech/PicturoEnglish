import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/call_cubit/call_socket_handle_cubit.dart';

import '../../services/navigation_service.dart';

class IOSBackgroundSocketManager {
  static Timer? _keepAliveTimer;
  
  static void startKeepAlive() {
    if (!Platform.isIOS) return;
    
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) {
        // Keep socket connection alive
        final cubit = NavigationService.instance.navigationKey.currentContext
            ?.read<CallSocketHandleCubit>();
        
        if (cubit?.callSocket?.connected == true) {
          cubit?.callSocket?.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          log('📡 iOS keep-alive ping sent');
        } else {
          log('⚠️ Socket disconnected, reconnecting...');
          cubit?.initCallSocket();
        }
      },
    );
  }
  
  static void stopKeepAlive() {
    _keepAliveTimer?.cancel();
  }
}
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:picturo_app/classes/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class GlobalSocketService {
  static final GlobalSocketService _instance = GlobalSocketService._internal();
  factory GlobalSocketService() => _instance;
  GlobalSocketService._internal();

  IO.Socket? socket;
  final NotificationService _notificationService = NotificationService();
  bool _isAppInForeground = false;
  bool _isChatScreenVisible = false;
  int? _currentChatUserId;

  Future<void> initialize() async {
    try {
      // Set up HTTP overrides for SSL certificate issues
      HttpOverrides.global = MyHttpOverrides();
      
      await _connectSocket();
      _setupListeners();
      log('✅ Global socket service initialized');
    } catch (e) {
      log('❌ Failed to initialize global socket: $e');
    }
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) {
      log('⚠️ User ID not found, skipping socket connection');
      return;
    }

    // Your socket server URL - make sure it's correct
    const String serverUrl = 'https://picturoenglish.com:2025';
    
    // Create socket with proper configuration to handle SSL issues
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'userId': userId},
      'secure': true,
      'rejectUnauthorized': false, // This is important for self-signed certificates
    });

    // Add connection event handlers
    socket?.on('connect', (_) {
      log('🌐 Global socket connected successfully');
    });

    socket?.on('connect_error', (error) {
      log('❌ Socket connection error: $error');
    });

    socket?.on('connect_timeout', (_) {
      log('⏰ Socket connection timeout');
    });

    socket?.connect();
  }

  void _setupListeners() {
    socket?.on('connect', (_) {
      log('🌐 Global socket connected');
    });

    socket?.on('disconnect', (_) {
      log('🌐 Global socket disconnected');
    });

    socket?.on('newMessage', (data) {
      log('🌐 Global socket message received: $data');
      _handleIncomingMessage(data);
    });

    socket?.on('error', (error) {
      log('❌ Global socket error: $error');
    });
  }

  void setAppState(bool inForeground) {
    _isAppInForeground = inForeground;
  }

  void setChatScreenState(bool isVisible, {int? userId}) {
    _isChatScreenVisible = isVisible;
    _currentChatUserId = userId;
  }

  bool _shouldShowNotification(Map<String, dynamic> data) {
  // Don't show if app is in foreground and user is in the chat
  final senderId = data['sender_id']?.toString();
  final currentChatUserId = _currentChatUserId?.toString();
  
  if (_isAppInForeground && _isChatScreenVisible && senderId == currentChatUserId) {
    log('🔇 Not showing socket notification - user is in the chat');
    return false;
  }
  
  // Additional validation
  if (data['sender_id'] == null || data['sender_username'] == null) {
    log('⚠️ Skipping notification with null sender info');
    return false;
  }
  
  return true;
}

  void _handleIncomingMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      log('❌ Invalid socket message format');
      return;
    }

    if (data.isEmpty || 
      data['sender_id'] == null || 
      data['sender_username'] == null ||
      data['message'] == null) {
    log('⚠️ Skipping socket message with missing data');
    return;
  }

    if (!_shouldShowNotification(data)) {
      return;
    }

    try {

       data['type'] = 'socket_message';

      final senderId = data['sender_id']?.toString();
      final senderUsername = data['sender_username']?.toString();
      final message = data['message']?.toString() ?? "New message";

      if (senderId == null || senderUsername == null || message.isEmpty) {
      log('⚠️ Skipping socket notification with null values');
      return;
    }

      log('📨 Processing socket notification: from $senderUsername');

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _notificationService.showMessageNotification(
        title: senderUsername ?? "Unknown User",
        body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
        payload: json.encode({
          'sender_id': senderId,
          'sender_username': senderUsername,
          'message': message,
          'type': 'socket_message',
        }),
        id: notificationId,
      );

      log('📢 Socket notification shown for message from $senderUsername');
    } catch (e) {
      log('❌ Failed to show socket notification: $e');
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket?.destroy();
    socket = null;
  }
}

// Global instance
final globalSocketService = GlobalSocketService();
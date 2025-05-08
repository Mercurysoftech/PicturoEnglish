// lib/socket/socket_service.dart
import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:picturo_app/socket/validateservercertificate.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService with ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  
  IO.Socket? _socket;
  String? _currentUserId;
  Function(dynamic)? _currentMessageHandler;
  bool _isInitialized = false;
  Map<String, bool> onlineUsers = {};
  SecurityContext? _securityContext;

  SocketService._internal();

  Future<void> _initializeSecurityContext() async {
  try {
    _securityContext = SecurityContext(withTrustedRoots: false);
    
    // Load DER certificate
    final certBytes = await rootBundle.load('assets/certificates/certificate.der');
    _securityContext!.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
    
    print('Security context initialized with DER certificate');
  } catch (e) {
    print('Error initializing security context: $e');
    rethrow;
  }
}

  Future<void> initialize(String userId, {Function(dynamic)? messageHandler}) async {
  if (_isInitialized && _currentUserId == userId) return;

  _currentUserId = userId;
  _isInitialized = true;
  _disconnect();

  print('Initializing socket for user: $userId');

  // // Validate pinned certificate before connecting
   final isCertValid = await validatePinnedCertificate(
    'picturoenglish.com',
     2025,
   );

  if (!isCertValid) {
    print('Certificate validation failed. Aborting socket connection.');
    return;
  }

  try {
    // if (_securityContext == null) {
    //   await _initializeSecurityContext();
    // }

    _socket = IO.io(
      'https://picturoenglish.com:2025',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setReconnectionAttempts(5)
        .setReconnectionDelay(1000)
        .enableAutoConnect()
        .setExtraHeaders({'Accept': 'application/json'})
        .setReconnectionDelayMax(5000)
        .build(),
    );

    if (messageHandler != null) {
      listenForMessages(messageHandler);
    }

    // await Future(() {
    //   _socket!.connect();
    // });

    // // _socket?.onConnect((_) {
    // //   print('Socket connected, registering user: $_currentUserId');
    // //   _socket?.emit('register', _currentUserId);
    // // });

    _setupEventListeners();
    print('Socket initialization completed');
  } catch (e) {
    print('Socket initialization failed: $e');
    rethrow;
  }
}


  void _setupEventListeners() {
    print('Socket Connected: ${_socket?.connected}');
    _socket?.onConnect((_) {
      print('Socket connected, registering user: $_currentUserId');
      _socket?.emit('register', _currentUserId);
    });
    
    _socket?.onDisconnect((_) => print('Socket disconnected'));
    _socket?.onError((data) => log('Socket error: $data'));
    _socket?.onReconnect((_) => print('Socket reconnected'));
    _socket?.onReconnectAttempt((attempt) => print('Reconnection attempt $attempt'));
    
    _socket?.on("chatHistory", (data) => print("Chat history received: $data"));
    _socket?.on("newMessage", (data) => print("New message: $data"));
    _socket?.on("userTyping", (data) => print("User typing: $data"));
    _socket?.on("userStoppedTyping", (data) => print("User stopped typing: $data"));
    _socket!.on("userOnline", (onlinedata) {
      print("User online: $onlinedata");
      String userId = onlinedata["user_id"];
      print('online user: $userId');
      onlineUsers[userId] = true;
      notifyListeners();
    });

    _socket!.on("userOffline", (data) {
      print("User offline: $data");
      String userId = data["user_id"];
      onlineUsers[userId] = false;
      notifyListeners();
    });
    _socket?.on("notification", (data) => print("Notification: $data"));
    _socket?.on("chatRequestNotification", (data) => print("Chat request notification: $data"));
  }

  bool isUserOnline(String userId) {
    print('isUser $userId isOnline: ${onlineUsers[userId]?? false}');
    print('onlineUsers: ${onlineUsers[userId]}');
    return onlineUsers[userId] ?? false;
  }

  void listenForMessages(Function(dynamic) messageHandler) {
    _socket?.off('newMessage');
    _currentMessageHandler = messageHandler;
    _socket?.on('newMessage', (data) {
      print('Received message: $data');
      messageHandler(data);
    });
  }

  void sendTypingStatus(String receiverId, bool isTyping) {
    if (_socket?.connected != true) return;
    
    final eventName = isTyping ? 'userTyping' : 'userStoppedTyping';
    _socket?.emit(eventName, {
      'sender_id': _currentUserId,
      'receiver_id': receiverId,
    });
  }

  void listenForTypingStatus(Function(dynamic) typingHandler) {
    _socket?.off('userTyping');
    _socket?.off('userStoppedTyping');
    
    _socket?.on('userTyping', (data) {
      print('User is typing: $data');
      typingHandler({'is_typing': true, ...data});
    });
    
    _socket?.on('userStoppedTyping', (data) {
      print('User stopped typing: $data');
      typingHandler({'is_typing': false, ...data});
    });
  }

  void listenForOnlineStatus(Function(dynamic) onlineHandler) {
    _socket?.off('userOnline');
    _socket?.off('userOffline');
    
    _socket?.on('userOnline', (data) {
      print('User online: $data');
      onlineHandler({'is_online': true, ...data});
    });
    
    _socket?.on('userOffline', (data) {
      print('User offline: $data');
      onlineHandler({'is_online': false, ...data});
    });
  }

  void sendMessage(dynamic messageData) {
    if (_socket?.connected != true) {
      print('Socket not connected, cannot send message');
      return;
    }
    print('Sending message: $messageData');
    _socket?.emit('sendMessage', messageData);
  }

  void removeEventListeners() {
    _socket?.off("chatHistory");
    _socket?.off("newMessage");
    _socket?.off("userTyping");
    _socket?.off("userStoppedTyping");
    _socket?.off("userOnline");
    _socket?.off("userOffline");
    _socket?.off("notification");
    _socket?.off("chatRequestNotification");
  }

  void _disconnect() {
    if (_socket != null) {
      print('Disconnecting socket...');
      _socket?.disconnect();
      _socket?.clearListeners();
      _socket = null;
    }
    _isInitialized = false;
  }

  @override
  void dispose() {
    super.dispose();
    removeEventListeners();
    _disconnect();
  }
}


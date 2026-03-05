import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/user_status/user_status_cubit.dart';
import 'package:picturo_app/main.dart';
import 'package:picturo_app/providers/online_status_provider.dart';
import 'package:picturo_app/services/navigation_service.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  static IO.Socket? socket;
  static String? _connectedUserId;
  static Map<String, bool> _onlineStatusCache = {};
  static Map<String, DateTime> _lastSeenCache = {};
  static List<Function(String, bool)> _statusListeners = [];
  static UserStatusCubit? _userStatusCubit;
  static bool _isConnecting = false;

  static void init(UserStatusCubit cubit) {
    _userStatusCubit = cubit;
  }

  static Future<void> connectSocket() async {
    // Prevent multiple simultaneous connection attempts
    if (_isConnecting) {
      log("⚠️ ChatSocket: Connection already in progress, skipping.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload from disk to avoid stale data
    final userId = prefs.getString('user_id');

    log("🔌 ChatSocket: connectSocket called. Prefs userId: $userId, Current connected: $_connectedUserId, Socket connected: ${socket?.connected}");

    // Don't connect if no user is logged in
    if (userId == null || userId.isEmpty) {
      log("⚠️ No user_id found, skipping chat socket connection");
      return;
    }

    // If socket exists and connected, check if it's for the SAME user
    if (socket != null && socket!.connected) {
      if (_connectedUserId == userId) {
        log("⚡ Chat socket already connected for user $userId. Re-emitting online status.");
        await _emitOnlineStatus();
        return;
      }
      // Different user - disconnect old socket first
      log("🔄 Chat socket connected for user $_connectedUserId but current user is $userId. Reconnecting...");
      try {
        socket!.disconnect();
        socket!.dispose();
        socket = null;
        _connectedUserId = null;
      } catch (e) {
        log("⚠️ Error disconnecting old user's chat socket: $e");
      }
    }

    // Disconnect any existing socket before creating new one
    if (socket != null) {
      try {
        socket!.disconnect();
        socket!.dispose();
        socket = null;
        log("🔌 Disconnected old chat socket for new user");
      } catch (e) {
        log("⚠️ Error disconnecting old socket: $e");
      }
    }

    socket = IO.io('https://picturoenglish.com:2025', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': Platform.isIOS ? 15 : 10,
      'reconnectionDelay': Platform.isIOS ? 1000 : 2000,
      'reconnectionDelayMax': 5000,
      'timeout': 20000,
      'forceNew': true, // 🔥 Force new connection
    });

    _isConnecting = true;
    socket?.connect();
    _connectedUserId = userId;

    final token = await FirebaseMessaging.instance.getToken();

    socket?.onConnect((_) {
      _isConnecting = false;
      log("✅ Chat socket connected for user: $userId");
      socket?.emit("userOnline", {'user_id': userId, 'is_online': true});
      socket?.emit('register', {"user_id": userId, "fcm_token": token});
      // Request the list of currently online users so we have initial state
      socket?.emit('getOnlineUsers');
    });

    // 🔥 Listen for online/offline of all users
    socket?.on('userOnline', (data) {
      final id = data['user_id'].toString();
      final isOnline = data['is_online'] ?? true;
      log("🟢 $id is online");
      _userStatusCubit?.setUserStatus(id, isOnline);
    });

    socket?.on('userOffline', (data) {
      final id = data['user_id'].toString();
      log("🔴 $id is offline");
      _userStatusCubit?.setUserStatus(id, false);
    });

    // Handle the list of online users (response to getOnlineUsers)
    socket?.on('onlineUsers', (data) {
      log("📋 Received online users list: $data");
      if (data is List) {
        for (var user in data) {
          final id = user.toString();
          _userStatusCubit?.setUserStatus(id, true);
          _onlineStatusCache[id] = true;
        }
      } else if (data is Map) {
        // Some servers send { userId: true/false, ... }
        data.forEach((key, value) {
          final id = key.toString();
          final isOnline = value == true;
          _userStatusCubit?.setUserStatus(id, isOnline);
          _onlineStatusCache[id] = isOnline;
        });
      }
    });

    // Handle response for single user status check
    socket?.on('userStatus', (data) {
      if (data is Map) {
        final id = data['user_id']?.toString();
        final isOnline = data['is_online'] == true;
        if (id != null) {
          log("👤 User $id status: ${isOnline ? 'online' : 'offline'}");
          _userStatusCubit?.setUserStatus(id, isOnline);
          _onlineStatusCache[id] = isOnline;
        }
      }
    });

    socket?.onDisconnect((_) {
      log("🔌 Socket disconnected");
      _isConnecting = false;
    });
    socket?.onConnectError((err) {
      log("❌ Connect error: $err");
      _isConnecting = false;
    });
    socket?.onError((err) => log("⚠️ Socket error: $err"));

    socket?.on('messageBlocked', (data) {
      print('❌ Message blocked event received: $data');
    });

    socket?.on('newMessage', (data) {
      try {
        log("📩 NewMessage: ${const JsonEncoder.withIndent('  ').convert(data)}");
      } catch (_) {
        log("📩 NewMessage: $data");
      }

      final senderId = data['sender_id']?.toString() ?? '';
      final userName = data['sender_username']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';

      if (ChatScreenTracker.activeChatUserId != senderId) {
        SocketNotificationsService.showNotification(
          title: userName,
          body: message,
          payloadData: data,
        );
      }
    });

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (userId != null && socket!.connected) {
        socket?.emit('register', {"user_id": userId, "fcm_token": newToken});
      }
    });
  }

  static void _handleOnlineEvent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        _onlineStatusCache[userId] = true;
        _notifyStatusChange(userId, true);
      }
    }
  }

  static void _handleOfflineEvent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        _onlineStatusCache[userId] = false;
        _lastSeenCache[userId] = DateTime.now();
        _notifyStatusChange(userId, false);
      }
    }
  }

  static void _notifyStatusChange(String userId, bool isOnline) {
    try {
      final context = NavigationService.instance.navigationKey.currentContext;
      if (context != null) {
        context.read<OnlineStatusProvider>().updateUserStatus(userId, isOnline);
      }
    } catch (e) {
      log("⚠️ Error notifying status change: $e");
    }
  }

  /// Request online status for a specific user from the server.
  /// Call this when opening a ChatScreen to get the target user's current status.
  static void requestUserOnlineStatus(String userId) {
    if (socket != null && socket!.connected) {
      socket!.emit('checkOnline', {'user_id': userId});
      log("🔍 Requesting online status for user $userId");
    }
  }

  static bool? getUserStatus(String userId) {
    return _onlineStatusCache[userId];
  }

  static String getLastSeen(String userId) {
    final lastSeen = _lastSeenCache[userId];
    if (lastSeen == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  static Future<void> dispose() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null && socket?.connected == true) {
      socket?.emit("userOnline", {"user_id": userId, "is_online": false});
    }

    socket?.disconnect();
    socket?.dispose();
    socket = null;
    _connectedUserId = null;
    _isConnecting = false;
  }

  /// Full cleanup for logout - clears all static caches and resets state
  static Future<void> fullCleanupForLogout() async {
    log("🧹 Starting ChatSocket full cleanup...");

    // Emit offline status before disconnecting
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null && socket?.connected == true) {
        socket?.emit("userOnline", {"user_id": userId, "is_online": false});
        log("✅ Emitted offline status");
      }
    } catch (e) {
      log("⚠️ Error emitting offline status: $e");
    }

    // Force disconnect socket
    try {
      socket?.disconnect();
      log("✅ Chat socket disconnected");
    } catch (e) {
      log("⚠️ Error disconnecting chat socket: $e");
    }

    // Force dispose socket
    try {
      socket?.dispose();
      log("✅ Chat socket disposed");
    } catch (e) {
      log("⚠️ Error disposing chat socket: $e");
    }

    socket = null;
    _connectedUserId = null;
    _isConnecting = false;

    // Clear all static caches
    _onlineStatusCache.clear();
    _lastSeenCache.clear();
    _statusListeners.clear();
    _userStatusCubit = null;

    log("🧹 ChatSocket fully cleaned up for logout - DONE");
  }

  /// Re-emit online status when socket is already connected.
  static Future<void> _emitOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null && socket?.connected == true) {
        socket?.emit("userOnline", {'user_id': userId, 'is_online': true});
        log("✅ Re-emitted online status for user: $userId");
      }
    } catch (e) {
      log("⚠️ Error re-emitting online status: $e");
    }
  }

  /// Emit offline status for the current user.
  static Future<void> emitOfflineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null && socket?.connected == true) {
        socket?.emit("userOnline", {"user_id": userId, "is_online": false});
        log("✅ Emitted offline status for user: $userId");
      }
    } catch (e) {
      log("⚠️ Error emitting offline status: $e");
    }
  }

  /// Whether the socket is currently connected.
  static bool get isConnected => socket?.connected ?? false;

  /// Ensure socket is connected; reconnect if not.
  static Future<void> ensureConnected() async {
    if (!isConnected && !_isConnecting) {
      log("🔄 ensureConnected: socket not connected, reconnecting...");
      await connectSocket();
    }
  }
}

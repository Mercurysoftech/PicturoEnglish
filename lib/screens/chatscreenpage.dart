import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picturo_app/classes/services/notification_service.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/screens/chatmessagelayout.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/services/global_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/call_cubit/get_friends_list_cubit/get_friends_list_cubit.dart';
import '../cubits/user_friends_cubit/user_friends_cubit.dart';
import '../responses/friends_response.dart';
import '../services/chat_socket_service.dart';
import '../utils/common_file.dart';
import 'call/calling_widget.dart';

enum ChatMenuAction {
  //enum class for menu option like "block user"...etc
  block,
}

class ChatScreen extends StatefulWidget {
  final String userName;
  final Widget avatarWidget;
  final int userId;
  final int profilePicId;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.avatarWidget,
    required this.userId,
    required this.profilePicId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ApiService _apiService;

  bool _isLoading = true;
  final String baseUrl = "https://picturoenglish.com/";
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final prefs = SharedPreferences.getInstance();
  final NotificationService _notificationService = NotificationService();

  bool _isOnline = false;
  Timer? _typingTimer;
  bool _isUserTyping = false;
  String? _userId;
  bool _isScreenVisible = true;
  final _notificationIds = <int>[];

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    initSocket();
    _setupTypingListener();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _notificationService.init();
    });

       globalSocketService.setChatScreenState(
      true, 
      userId: widget.userId
    );
    
  }

//--------------------------------------------New Updates Start-----------------------------------

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  // Update your initSocket method with better logging
  void initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    _userId = userId;

    try {
      await ChatSocket.connectScoket();

      // Add connection status logging
      ChatSocket.socket?.onConnect((_) {
        log('✅ Socket connected successfully');
      });

      ChatSocket.socket?.onDisconnect((_) {
        log('❌ Socket disconnected');
      });

      ChatSocket.socket?.onConnectError((error) {
        log('🚨 Socket connection error: $error');
      });

      // Enhanced newMessage handler with detailed logging
      ChatSocket.socket?.on('newMessage', (data) {
        log('📨 Received newMessage event');
        log('📦 Raw data type: ${data.runtimeType}');
        log('📦 Raw data: $data');

        if (data is Map) {
          log('🗂️ Data keys: ${data.keys.toList()}');
          log('🔍 Sender ID: ${data['sender_id']}');
          log('🔍 Receiver ID: ${data['receiver_id']}');
          log('💬 Message: ${data['message']}');
        }

        _handleIncomingMessage(data);
      });

      // Enhanced error handling
      ChatSocket.socket?.onError((error) {
        log('💥 Socket error: $error', error: error is Error ? error : null);
      });

      // Other event handlers...
      ChatSocket.socket?.on('userOnline', (data) {
        log('🟢 User online: $data');
        _handleOnlineStatus({'user_id': data['user_id'], 'is_online': true});
      });

      ChatSocket.socket?.on('userOffline', (data) {
        log('🔴 User offline: $data');
        _handleOnlineStatus({'user_id': data['user_id'], 'is_online': false});
      });
    } catch (e) {
      log('❌ Failed to initialize socket: $e');
    }
  }

  void _showMessageNotification({
    required String senderName,
    required String message,
    required Map<String, dynamic> messageData,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationService.showMessageNotification(
        title: senderName,
        body:
            message.length > 100 ? '${message.substring(0, 100)}...' : message,
        payload: json.encode({
          'sender_id': messageData['sender_id'],
          'sender_username': messageData['sender_username'],
          'message': messageData['message'],
          'receiver_id': messageData['receiver_id'],
        }),
        id: notificationId,
      );

      log('📢 Notification shown for message from $senderName');
    } catch (e) {
      log('❌ Failed to show notification: $e');
    }
  }

// Update your sendMessage with logging
  void sendMessage(String senderId, String receiverId, String message) {
    final messageId = "msg_${DateTime.now().millisecondsSinceEpoch}";
    String now = DateTime.now().toUtc().toIso8601String();

    final messageData = {
      "message_id": messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      "notify_message": {
        "from": senderId,
        "message": message,
        "message_id": messageId,
        "timestamp": now
      },
    };

    log('📤 Sending message: $messageData');

    ChatSocket.socket?.emit('sendMessage', messageData);
  }

  void _handleIncomingMessage(dynamic data) {
    if (!mounted) return;

    log('🔄 Processing incoming message');

    if (data is! Map<String, dynamic>) {
      log('❌ Invalid message format: Expected Map<String, dynamic>, got ${data.runtimeType}');
      log('❌ Raw data: $data');
      return;
    }

    final senderId = data['sender_id']?.toString();
    final senderUserName = data['sender_username']?.toString();
    final receiverId = data['receiver_id']?.toString();
    final messageText = data['message']?.toString();
    final timestamp = data['timestamp']?.toString();

    log('👤 Sender ID: $senderId');
    log('👤 Sender Username: $senderUserName');
    log('🎯 Receiver ID: $receiverId');
    log('💬 Message: $messageText');
    log('🧑 My User ID: $_userId');
    log('👥 Target User ID: ${widget.userId}');

    // Check if message is for current user and from current chat user
    final isForMe = receiverId == _userId;
    final isFromCurrentChat = senderId == widget.userId.toString();

    if (isForMe || isFromCurrentChat) {
      log('✅ Message is for current chat - adding to UI');
      setState(() {
        _messages.insert(0, {
          "senderId": senderId,
          "message": messageText ?? "",
          "timestamp": timestamp ?? getCurrentFormattedTime(),
        });
      });
      print(
          'the receiving notification Condition: ${isForMe && !_isScreenVisible}');
      // Show notification if app is in background or not on this chat screen
      if (isForMe || !_isScreenVisible) {
        _showMessageNotification(
          senderName: senderUserName ?? 'N/A',
          message: messageText ?? "New message",
          messageData: data,
        );
      }
    } else {
      log('❌ Message not for current chat - ignoring');
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _messages.clear();
    }
  }

  Future<void> _initializeApiService() async {
    try {
      _apiService = await ApiService.create();

      await _loadMessages();
    } catch (e) {
      print("Error initializing API service: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response =
          await _apiService.fetchMessages(receiverId: widget.userId);
      final messages = response.messages;

      setState(() {
        _messages.addAll(
          messages.reversed.map((msg) => {
                "senderId": msg.senderId.toString(),
                "message": msg.message,
                "timestamp": msg.formattedTime,
              }),
        );
      });
    } catch (e) {
      print("Failed to load messages: $e");
    }
  }

  void _setupTypingListener() {
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        ChatSocket.socket?.emit('typing', {
          'sender_id': _userId,
          'receiver_id': widget.userId.toString(),
        });

        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 1), () {
          ChatSocket.socket?.emit('stopTyping', {
            'sender_id': _userId,
            'receiver_id': widget.userId.toString(),
          });
        });
      }
    });
  }

  void _handleTypingStatus(dynamic data) {
    if (!mounted) return;

    if (data is Map<String, dynamic>) {
      final senderId = data['sender_id']?.toString();
      final isTyping = data['is_typing'] as bool? ?? false;

      if (senderId == widget.userId.toString()) {
        setState(() {
          _isUserTyping = isTyping;
        });

        // Automatically reset typing status after 3 seconds if no new typing events come in
        if (isTyping) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _isUserTyping) {
              setState(() {
                _isUserTyping = false;
              });
            }
          });
        }
      }
    }
  }

  void _handleOnlineStatus(dynamic data) {
    if (!mounted) return;

    if (data is Map<String, dynamic>) {
      final userId = data['user_id']?.toString();
      final isOnline = data['is_online'] as bool? ?? false;

      if (userId == widget.userId.toString()) {
        setState(() {
          _isOnline = isOnline;
          if (!isOnline) {
            _isUserTyping = false;
          }
        });
      }
    }
  }

//   void _handleIncomingMessage(dynamic data) {
//   if (!mounted) return;

//   if (data is! Map<String, dynamic>) {
//     print('Invalid message format: $data');
//     return;
//   }

//   final senderId = data['sender_id']?.toString();
//   final receiverId = data['receiver_id']?.toString();

//   if (receiverId == _userId || senderId == widget.userId.toString()) {
//     setState(() {
//       _messages.insert(0, {
//         "senderId": senderId,
//         "message": data['message']?.toString() ?? "",
//         "timestamp": data['timestamp']?? getCurrentFormattedTime(),
//       });
//     });
//   }
// }
  String getCurrentFormattedTime() {
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a'); // 12-hour format with AM/PM
    return formatter.format(now);
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();

      _userId = prefs.getString('user_id');
      print("My UserId : ${_userId}");
      final receiverId = widget.userId.toString();
      final now = _formatTimeTo12Hour(
          DateTime.now().toIso8601String()); // Get current time in ISO format
      sendMessage(
          _userId.toString(), receiverId, _messageController.text.trim());
      setState(() {
        _messages.insert(0, {
          "senderId": _userId.toString(),
          "message": _messageController.text.trim(),
          "timestamp": now,
          "isOptimistic": true,
        });
      });
      _messageController.clear();
    }
  }

  String _formatTimeTo12Hour(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = timestamp.contains('T')
          ? DateTime.parse(timestamp)
          : DateTime.tryParse(timestamp) ?? DateTime.now();

      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');

      // Convert to 12-hour format
      final period = hour >= 12 ? 'PM' : 'AM';
      final twelveHour = hour % 12;
      final displayHour = twelveHour == 0 ? 12 : twelveHour;

      return '$displayHour:$minute $period';
    } catch (e) {
      print('Error formatting time: $e');
      return '';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      LifecycleEventHandler(
        resumeCallBack: () {},
        suspendCallBack: () {},
      ),
    );
    _typingTimer?.cancel();
    _messageController.dispose();
    globalSocketService.setChatScreenState(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Homepage(initialIndex: 1), // 👈 index of ChatListPage
          ),
          (route) => false,
        );
        return false;
      },
<<<<<<< Updated upstream
      child: Scaffold(
        backgroundColor: Color(0xFFE0F7FF),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: AppBar(
            backgroundColor: Color(0xFF49329A),
            leading: InkWell(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Homepage(initialIndex: 1), // 👈 index of ChatListPage
                  ),
                  (route) => false,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 18),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    context.read<GetFriendsListCubit>().fetchAllFriends();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Homepage(
                            initialIndex: 1), // 👈 index of ChatListPage
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
            leadingWidth: 22,
            title: Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
              ),
              child: Row(
                children: [
                  InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: SizedBox(
                        width: 14,
                        height: 32,
                      )),
                  InkWell(
                      onTap: () {
                        context.read<GetFriendsListCubit>().fetchAllFriends();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Homepage(
                                initialIndex: 1), // 👈 index of ChatListPage
                          ),
                          (route) => false,
                        );
                      },
                      child: widget.avatarWidget),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          widget.userName,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins Regular',
                              fontSize: 16),
                        ),
                      ),
                      Text(
                        _isUserTyping
                            ? 'Typing...'
                            : _isOnline
                                ? 'Online'
                                : 'Offline',
                        style: TextStyle(
                            color: _isUserTyping
                                ? Colors.green
                                : _isOnline
                                    ? Colors.white
                                    : Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins Regular'),
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
=======
      child: BlocListener<CallSocketHandleCubit, CallSocketHandleState>(
        listener: (context, state) {
          
          if (state is CallErrorState) {
            Fluttertoast.showToast(
              msg: state.message,
              backgroundColor: Colors.red,
            );
          }
        },
        child: Scaffold(
          backgroundColor: Color(0xFFE0F7FF),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: AppBar(
              backgroundColor: Color(0xFF49329A),
              leading: InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Homepage()),
                    (route) => false, // remove everything from backstack
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 18),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      context.read<GetFriendsListCubit>().fetchAllFriends();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Homepage()),
                        (route) => false, // remove everything from backstack
                      );
                    },
                  ),
                ),
              ),
              leadingWidth: 22,
              title: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                ),
>>>>>>> Stashed changes
                child: Row(
                  children: [
                    InkWell(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const Homepage()),
                            (route) =>
                                false, // remove everything from backstack
                          );
                        },
                        child: SizedBox(
                          width: 14,
                          height: 32,
                        )),
                    InkWell(
                        onTap: () {
                          context.read<GetFriendsListCubit>().fetchAllFriends();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const Homepage()),
                            (route) =>
                                false, // remove everything from backstack
                          );
                        },
                        child: widget.avatarWidget),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            widget.userName,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins Regular',
                                fontSize: 16),
                          ),
                        ),
                        BlocBuilder<UserStatusCubit, Map<String, bool>>(
                          builder: (context, userStatus) {
                            final isOnline =
                                userStatus[widget.userId.toString()] ?? false;

                            return Text(
                              _isUserTyping
                                  ? 'Typing...'
                                  : isOnline
                                      ? 'Online'
                                      : 'Offline',
                              style: TextStyle(
                                color: _isUserTyping
                                    ? Colors.green
                                    : isOnline
                                        ? Colors.white
                                        : Colors.white,
                                fontSize: 12,
                                fontFamily: 'Poppins Regular',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    children: [
                      CoinBadge(),
                      SizedBox(
                        width: 5,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (context
                                .read<CallSocketHandleCubit>()
                                .isLiveCallActive) {
                              Fluttertoast.showToast(
                                msg: "You're already in another call",
                                backgroundColor: Colors.orange,
                              );
                            } else {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              String? userId = prefs.getString("user_id");

                              int? profileProvider =
                                  userId != null && userId != ''
                                      ? int.tryParse(userId)
                                      : null;

                              if (profileProvider != null) {
                                await requestPermissions();

                                context
                                    .read<CallSocketHandleCubit>()
                                    .resetCubit();

                                context
                                    .read<CallSocketHandleCubit>()
                                    .emitCallingFunction(
                                      targetId: widget.userId ?? 0,
                                      currentUserId: profileProvider,
                                      targettedUserName: "${widget.userName}",
                                    );
                                // Navigate first
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CallingScreen(
                                      currentUserId: profileProvider,
                                      callerName: widget.userName,
                                      avatarUrl: widget.profilePicId,
                                      friendId: widget.userId,
                                    ),
                                  ),
                                );

                                // Emit socket events

                                // Reset timer if not in active call
                                if (!context
                                    .read<CallSocketHandleCubit>()
                                    .isLiveCallActive) {
                                  context.read<CallTimerCubit>().resetTimer();
                                }
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(70),
                          child: Container(
                            padding: EdgeInsets.all(5),
                            child: SvgPicture.string(
                              Svgfiles.svgString,
                              width: 28,
                              height: 28,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuButton<ChatMenuAction>(
                        icon: Icon(Icons.more_vert,
                            color: Colors.white, size: 28),
                        onSelected: (ChatMenuAction result) {
                          if (result == ChatMenuAction.block) {
                            _showBlockConfirmationDialog();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<ChatMenuAction>>[
                          const PopupMenuItem<ChatMenuAction>(
                            value: ChatMenuAction.block,
                            child: Text(
                              'Block User',
                              style: TextStyle(
                                  fontFamily: AppConstants.commonFont),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE0F7FF),
                        Color(0xFFEAE4FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.all(8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message["senderId"] == _userId;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ChatMessageLayout(
                                isMeChatting: isMe,
                                messageBody: message["message"] ?? "",
                                timestamp: message["timestamp"] ?? "null",
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: _sendMessage,
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF49329A),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: SvgPicture.string(
                                      Svgfiles.sendSvg,
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showBlockConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Block User',
            style: TextStyle(fontFamily: AppConstants.commonFont),
          ),
          content: Text(
            'Are you sure you want to block ${widget.userName}?',
            style: TextStyle(fontFamily: AppConstants.commonFont),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: AppConstants.commonFont),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Block',
                style: TextStyle(
                    color: Colors.red, fontFamily: AppConstants.commonFont),
              ),
              onPressed: () {
                // Add your block user logic here
                _blockUser();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> requestPermissions() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw Exception("Microphone permission not granted");
    }
  }

// Add this method to handle the actual blocking
  Future<void> _blockUser() async {
    try {
      // Implement your block user API call here
      // Example:
      await _apiService.blockUser(widget.userId);
      context.read<UserFriendsCubit>().fetchAllUsersAndFriends();
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User blocked successfully')),
      );

      // Optionally navigate back
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $e')),
      );
    }
  }

  void _handleAppResume() {
    _notificationService.cancelAll();
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final VoidCallback resumeCallBack;
  final VoidCallback suspendCallBack;

  LifecycleEventHandler({
    required this.resumeCallBack,
    required this.suspendCallBack,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        suspendCallBack();
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

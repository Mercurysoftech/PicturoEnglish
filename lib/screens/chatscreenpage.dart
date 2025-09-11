import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picturo_app/classes/services/notification_service.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/cubits/user_status/user_status_cubit.dart';
import 'package:picturo_app/main.dart';
import 'package:picturo_app/screens/chatmessagelayout.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
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

  bool _isOnline = false;
  Timer? _typingTimer;
  bool _isUserTyping = false;
  String? _userId;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    initSocket();
    ChatScreenTracker.activeChatUserId = widget.userId.toString();
    print(
        'User name received: ${widget.userName} and User ID: ${widget.userId}');
    _setupTypingListener();
  }

//--------------------------------------------New Updates Start-----------------------------------

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  void initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    _userId = userId;
    await ChatSocket.connectSocket();
    print("ksjdcnksjdcnksjcnsd ${ChatSocket.socket?.connected}");

    ChatSocket.socket?.on('newMessage', (data) {
      log("ksjdcnksjdcnksjcnsd  New Msg ${data}");
      _handleIncomingMessage(data);
    });

    ChatSocket.socket?.on('messageBlocked', (data) {
      log("🚫 Message Blocked Event: $data");
      if (mounted) {
        // _showMessageBlockedDialog(data['message'] ??
        //     "Cannot send message. One of the users is blocked.");
      }
      setState(() {
        _isBlocked = true;
      });
    });

    ChatSocket.socket?.onError((handler) {});
    ChatSocket.socket?.on('userOnline', (data) {
      _handleOnlineStatus({'user_id': data['user_id'], 'is_online': true});
    });

    ChatSocket.socket?.on('userOffline', (data) {
      _handleOnlineStatus({'user_id': data['user_id'], 'is_online': false});
    });

    ChatSocket.socket?.on('userTyping', (data) {
      _handleTypingStatus({
        'sender_id': data['sender_id'],
        'is_typing': true,
      });
    });

    ChatSocket.socket?.on('stopTyping', (data) {
      _handleTypingStatus({
        'sender_id': data['sender_id'],
        'is_typing': false,
      });
    });
  }

  void _showMessageBlockedDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Message Blocked',
          style: TextStyle(fontFamily: AppConstants.commonFont),
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: AppConstants.commonFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: AppConstants.commonFont),
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage(String senderId, String receiverId, String message) {
    final messageId = "msg_${DateTime.now().millisecondsSinceEpoch}";
    String now = DateTime.now().toUtc().toIso8601String();

    ChatSocket.socket?.emit('sendMessage', {
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
    });
    print("lsdjkvlskdcmlskd ${{
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
    }}");
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

  void _handleIncomingMessage(dynamic data) {
    if (!mounted) return;

    if (data is! Map<String, dynamic>) {
      print('Invalid message format: $data');
      return;
    }

    final senderId = data['sender_id']?.toString();
    final receiverId = data['receiver_id']?.toString();

    if (receiverId == _userId && senderId == widget.userId.toString()) {
      setState(() {
        _messages.insert(0, {
          "senderId": senderId,
          "message": data['message']?.toString() ?? "",
          "timestamp": data['timestamp'] ?? getCurrentFormattedTime(),
        });
      });
    }
  }

  String getCurrentFormattedTime() {
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a'); // 12-hour format with AM/PM
    return formatter.format(now);
  }

  void _sendMessage() async {
    if (_isBlocked) {
      _showMessageBlockedDialog(
          'Cannot send message. One of the users is blocked.');
      return;
    }
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
    _typingTimer?.cancel();
    _messageController.dispose();
    if (ChatScreenTracker.activeChatUserId == widget.userId.toString()) {
      ChatScreenTracker.activeChatUserId = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<GetFriendsListCubit>().fetchAllFriends();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
          (route) => false,
        );
        return false;
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
              child: Row(
                children: [
                  InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const Homepage()),
                          (route) => false, // remove everything from backstack
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
                          (route) => false, // remove everything from backstack
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
                            final prefs = await SharedPreferences.getInstance();
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
                      icon:
                          Icon(Icons.more_vert, color: Colors.white, size: 28),
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
                            style:
                                TextStyle(fontFamily: AppConstants.commonFont),
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
    );
  }

  void _showBlockConfirmationDialog() {
    FocusScope.of(context).unfocus();

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
      await _apiService.blockUser(widget.userId);

      // refresh friends on cubit
      context.read<UserFriendsCubit>().fetchAllUsersAndFriends();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User blocked successfully')),
      );

      // Pop ChatScreen with a result
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $e')),
      );
    }
  }
}

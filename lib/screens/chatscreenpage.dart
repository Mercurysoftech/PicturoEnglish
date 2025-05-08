import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/chatmessagelayout.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/socket/socketservice.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatMenuAction { //enum class for menu option like "block user"...etc
  block,
}

class ChatScreen extends StatefulWidget {
  final int profileId;
  final String userName;
  final int userId;
  
  const ChatScreen({
    super.key, 
    required this.profileId,
    required this.userName,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ApiService _apiService;
  String? _avatarUrl;
  bool _isLoading = true;
  final String baseUrl = "https://picturoenglish.com/";
  final SocketService _socketService = SocketService();
  bool _isSocketReady = false;
  

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final prefs = SharedPreferences.getInstance();

  // Typing and online status variables
  bool _isTyping = false;
  bool _isOnline = false;
  Timer? _typingTimer;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    _initSocket();
    _setupTypingListener();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // User changed, reset messages and reconnect socket
      _messages.clear();
       _initSocket();
    }
  }

  Future<void> _initializeApiService() async {
  try {
    _apiService = await ApiService.create();
    if (widget.profileId != 0) {
      await _loadAvatar();
    }

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
    final response = await _apiService.fetchMessages(receiverId: widget.userId);
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


  Future<void> _loadAvatar() async {
    try {
      final avatarResponse = await _apiService.fetchAvatars();
      print('Avatar with ID ${widget.profileId}');
      
      // Find the matching avatar
      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == widget.profileId,
        orElse: () {
          print('Avatar with ID ${widget.profileId} not found');
          throw Exception("Avatar not found");
        },
      );
      
      if (mounted) {
        setState(() {
          _avatarUrl = baseUrl + avatar.avatarUrl;
        });
      }
    } catch (e) {
      print("Error loading avatar: $e");
      if (mounted) {
        setState(() {
          _avatarUrl = null;
        });
      }
    }
  }



  Future<void> _initSocket() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    
    if (currentUserId == null || currentUserId.isEmpty) {
      print('No user_id found in SharedPreferences');
      return;
    }

    setState(() => _isSocketReady = false);
    
    await _socketService.initialize(
      currentUserId,
      messageHandler: _handleIncomingMessage,
    );
    
    print('current userId: $currentUserId');

    _socketService.listenForTypingStatus(_handleTypingStatus);
    _socketService.listenForOnlineStatus(_handleOnlineStatus);

    // Request initial online status
    // _socketService.sendMessage({
    //   'type': 'userOnline',
    //   'user_id': widget.userId.toString(),
    // });

    setState(() => _isSocketReady = true);
  } catch (e) {
    print('Error initializing socket: $e');
  }
}

  void _setupTypingListener() {
  _messageController.addListener(() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _socketService.sendTypingStatus(widget.userId.toString(), true);
      _startTypingTimer();
    } else if (_messageController.text.isEmpty && _isTyping) {
      _isTyping = false;
      _socketService.sendTypingStatus(widget.userId.toString(), false);
      _typingTimer?.cancel();
    }
  });
}

void _startTypingTimer() {
  _typingTimer?.cancel();
  _typingTimer = Timer(const Duration(seconds: 3), () {
    if (_isTyping) {
      _isTyping = false;
      _socketService.sendTypingStatus(widget.userId.toString(), false);
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
        // Reset typing status if user goes offline
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
  final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;
  
  // Only process messages meant for this chat
  if (receiverId == currentUserId || senderId == widget.userId.toString()) {
    setState(() {
      _messages.insert(0, {
        "senderId": senderId,
        "message": data['message']?.toString() ?? "",
        "timestamp": data['timestamp'] ,
      });
    });
  }
}

 void _sendMessage() {
  if (_messageController.text.trim().isEmpty || !_isSocketReady) return;

  final idProvider = Provider.of<UserProvider>(context, listen: false);
  final senderId = idProvider.userId;
  final receiverId = widget.userId.toString();

  final now = _formatTimeTo12Hour(DateTime.now().toIso8601String()); // Get current time in ISO format

  final messageData = {
    "sender_id": int.tryParse(senderId!) ?? 0,
    "receiver_id": int.tryParse(receiverId) ?? 0,
    "message": _messageController.text.trim(),
    "timestamp": now, // Include timestamp
  };

  // Optimistic UI update
  setState(() {
    _messages.insert(0, {
      "senderId": senderId,
      "message": _messageController.text.trim(),
      "timestamp": now,
      "isOptimistic": true,
    });
  });

  _socketService.sendMessage(messageData);
  _messageController.clear();
}

  ImageProvider _getAvatarImage() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      print('Avatar Url: $_avatarUrl');
      return CachedNetworkImageProvider(_avatarUrl!);
    } else if(widget.profileId == 0) {
      return AssetImage('assets/avatar2.png'); // Fallback if URL is not valid
    }
    else {
      return AssetImage('assets/avatar2.png'); // Fallback if URL is not valid
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
  _socketService.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final idProvider = Provider.of<UserProvider>(context);
    final currentUserId = idProvider.userId;
     bool isOnline = _socketService.isUserOnline(widget.userId.toString());

    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _getAvatarImage(),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Regular',
                        fontSize: 16
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
    fontFamily: 'Poppins Regular'
  ),
)

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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _startVoiceCall();
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
                  SizedBox(width: 10),
                 PopupMenuButton<ChatMenuAction>(
  icon: Icon(Icons.more_vert, color: Colors.white, size: 28),
  onSelected: (ChatMenuAction result) {
    if (result == ChatMenuAction.block) {
      _showBlockConfirmationDialog();
    }
  },
  itemBuilder: (BuildContext context) => <PopupMenuEntry<ChatMenuAction>>[
    const PopupMenuItem<ChatMenuAction>(
      value: ChatMenuAction.block,
      child: Text('Block User',style: TextStyle(fontFamily: 'Poppins Medium'),),
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
                        final isMe = message["senderId"] == currentUserId;
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: ChatMessageLayout(
                            isMeChatting: isMe,
                            messageBody: message["message"],
                            timestamp:message["timestamp"],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  void _showBlockConfirmationDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Block User',style: TextStyle(fontFamily: 'Poppins Medium'),),
        content: Text('Are you sure you want to block ${widget.userName}?',style: TextStyle(fontFamily: 'Poppins Medium'),),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel',style: TextStyle(fontFamily: 'Poppins Medium'),),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Block', style: TextStyle(color: Colors.red,fontFamily: 'Poppins Medium'),),
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

// Add this method to handle the actual blocking
Future<void> _blockUser() async {
  try {
    // Implement your block user API call here
    // Example:
    // await _apiService.blockUser(widget.userId);
    
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

  void _startVoiceCall() {
     Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VoiceCallScreen( callerId:widget.userId,callerName: widget.userName, callerImage:_avatarUrl!,isIncoming: false),
),
  );
  print('VoiceCall: ${widget.userId},${widget.userName},${_avatarUrl}}');
  }
}
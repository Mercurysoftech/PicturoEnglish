import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/screens/chatmessagelayout.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/socket/socketservice.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../responses/friends_response.dart';
import '../utils/common_file.dart';
import 'call/calling_widget.dart';
import 'call/widgets/call_socket_page.dart';
import 'call/widgets/check_web_call.dart';

enum ChatMenuAction { //enum class for menu option like "block user"...etc
  block,
}

class ChatScreen extends StatefulWidget {
  final int profileId;
  final String userName;
  final Widget avatarWidget;
  final Friends friendDetails;
  final int userId;
  
  const ChatScreen({
    super.key, 
    required this.profileId,
    required this.userName,
    required this.avatarWidget,
    required this.friendDetails,
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
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final prefs = SharedPreferences.getInstance();

  bool _isOnline = false;
  Timer? _typingTimer;
  bool _isUserTyping = false;
  String? _userId;
  @override
  void initState() {
    super.initState();
    _initializeApiService();
    initSocket();
    _setupTypingListener();
    _loadAvatar();
  }


//--------------------------------------------New Updates Start-----------------------------------

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  late IO.Socket socket;


  void initSocket( ) async{

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    _userId=userId;
    socket = IO.io('https://picturoenglish.com:2025', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnect((_) {
      socket.emit('register', userId);
    });
    socket.on('newMessage', (data) {
      _handleIncomingMessage(data);

    });
    socket.onError((handler){
      print('_____________ ____________ Erroer ${handler.toString()}');
    });
    socket.on('userOnline', (data) {
      _handleOnlineStatus({'user_id': data['user_id'], 'is_online': true});
    });

    socket.on('userOffline', (data) {
      _handleOnlineStatus({'user_id': data['user_id'], 'is_online': false});
    });

    socket.on('userTyping', (data) {
      _handleTypingStatus({
        'sender_id': data['sender_id'],
        'is_typing': true,
      });
    });

    socket.on('stopTyping', (data) {
      _handleTypingStatus({
        'sender_id': data['sender_id'],
        'is_typing': false,
      });
    });

  }

  void sendMessage(String senderId, String receiverId, String message) {
    socket.emit('sendMessage', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // User changed, reset messages and reconnect socket
      _messages.clear();
       // _initSocket();
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



  void _setupTypingListener() {
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        socket.emit('typing', {
          'sender_id': _userId,
          'receiver_id': widget.userId.toString(),
        });

        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 1), () {
          socket.emit('stopTyping', {
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


  if (receiverId == _userId || senderId == widget.userId.toString()) {
    setState(() {
      _messages.insert(0, {
        "senderId": senderId,
        "message": data['message']?.toString() ?? "",
        "timestamp": data['timestamp']?? getCurrentFormattedTime(),
      });
    });
  }
}
  String getCurrentFormattedTime() {
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a'); // 12-hour format with AM/PM
    return formatter.format(now);
  }
 void _sendMessage()async {
    if(_messageController.text.isNotEmpty){

      final prefs = await SharedPreferences.getInstance();

      _userId= prefs.getString('user_id');
      final receiverId = widget.userId.toString();

      final now = _formatTimeTo12Hour(DateTime.now().toIso8601String()); // Get current time in ISO format
      sendMessage(_userId.toString(),receiverId, _messageController.text.trim());
      setState(() {
        _messages.insert(0, {
          "senderId": _userId.toString(),
          "message": _messageController.text.trim(),
          "timestamp": now,
          "isOptimistic": true,
        });
      });




      //
      // final messageData = {
      //   "sender_id":_userId,
      //   "receiver_id": "$receiverId",
      //   "message": _messageController.text
      // };
      //
      // bool? response = await _apiService.sendMessagesToAPI(messageMap: messageData);
      // if(response!=null&&response){
      //   setState(() {
      //     _messages.insert(0, {
      //       "senderId": _userId.toString(),
      //       "message": _messageController.text.trim(),
      //       "timestamp": now,
      //       "isOptimistic": true,
      //     });
      //   });
      // }
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
    socket.dispose();
  _typingTimer?.cancel();
  _messageController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
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
              onPressed: (){
               Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                widget.avatarWidget,
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
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>CallingScreen(friendDetails: widget.friendDetails,callerName: "${widget.friendDetails.friendName}",avatarUrl: widget.friendDetails.friendProfilePic,)));
                        // Navigator.push(context, MaterialPageRoute(builder: (context)=>CallScreen( userId: '${widget.friendDetails.friendId}',)));

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
      child: Text('Block User',style: TextStyle(fontFamily: AppConstants.commonFont),),
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
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: ChatMessageLayout(
                            isMeChatting: isMe,
                            messageBody: message["message"] ?? "",
                            timestamp:message["timestamp"] ?? "null",
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
                      // onSubmitted: (_) => _sendMessage(),
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
        title: Text('Block User',style: TextStyle(fontFamily: AppConstants.commonFont),),
        content: Text('Are you sure you want to block ${widget.userName}?',style: TextStyle(fontFamily: AppConstants.commonFont),),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel',style: TextStyle(fontFamily: AppConstants.commonFont),),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Block', style: TextStyle(color: Colors.red,fontFamily: AppConstants.commonFont),),
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
    await _apiService.blockUser(widget.userId);
    
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

}
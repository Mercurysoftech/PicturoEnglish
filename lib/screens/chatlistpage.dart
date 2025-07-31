import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/responses/allusers_response.dart';
import 'package:picturo_app/responses/friends_response.dart';
import 'package:picturo_app/screens/alluserspage.dart';
import 'package:picturo_app/screens/calllogspage.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/widgets/chat_friends_tab.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/call_cubit/get_friends_list_cubit/get_friends_list_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../cubits/user_friends_cubit/user_friends_cubit.dart';
import '../services/chat_socket_service.dart';
import '../utils/common_app_bar.dart'; // Import your API service

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketMessageService {
  static final SocketMessageService _instance = SocketMessageService._internal();
  factory SocketMessageService() => _instance;
  SocketMessageService._internal();

  late IO.Socket _socket;

  IO.Socket get socket => _socket;

  bool _isInitialized = false;

  void init(String userId, void Function(dynamic data) onNotifyMessage) {
    if (_isInitialized) return;

    _socket = IO.io("https://picturoenglish.com:2026", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": true,
      "query": {"userId": userId.toString()},
    });

    _socket.connect();

    _socket.onConnect((_) {
      print("✅ Socket connected +++++++++++++++++");
    });

    _socket.on("notify_message", (data) {
      print("📥 Received notify_message: $data");

      onNotifyMessage(data); // Call the callback
    });
    _socket.on("chat_list_update", (data) {
      print("📥 Received ChatList: $data");

      onNotifyMessage(data); // Call the callback
    });

    _socket.onDisconnect((_) {
      print("❌ Socket disconnected");
    });

    _isInitialized = true;
  }

  void disconnect() {
    _socket.disconnect();
    _isInitialized = false;
  }
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // List to store fetched users
  List<User> allUsers = [];
  List<Friends> friends = [];
  bool isLoading = true;
  String errorMessage = '';
  List<User> filteredAllUsers = [];
  List<Friends> filteredFriends = [];
  int allUsersCount = 0;
  int friendsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);

    connectSocket();
    _fetchAllUsers();
    context.read<GetFriendsListCubit>().fetchAllFriends();
    connectSS();
  }
  void connectSS()async{
    final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;

    SocketMessageService().init(currentUserId, (data){
      log("skdjcnksjdcn ${data}");
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    SocketMessageService().disconnect();
    ChatSocket.dispose();
    super.dispose();
  }
  List<String>?  countViewList=[];
  Future<void>connectSocket()async{
    SharedPreferences preferences=await SharedPreferences.getInstance();
    List<String>? countViewedIndex=preferences.getStringList("Count_Viewed_Index");
    setState(() {
      countViewList=countViewedIndex;
    });
    await ChatSocket.connectScoket();
    // ChatSocket.socket.emit("userOnline",{});
    ChatSocket.socket.on('unreadCount', (data) {
      print("sdcmskdcs;dlcksd;lc,sd;cl, __ ${data}");
      context.read<GetFriendsListCubit>().fetchAllFriends();

    // updatedOne=false;
    // _fetchAllUsers();
    });

  }
  
  Future<void> _fetchAllUsers() async {
        context.read<UserFriendsCubit>().fetchAllUsersAndFriends();
  }

  void _updateCounts() {
  final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;
  setState(() {
    allUsersCount = allUsers.length;
    friendsCount = friends.where((f) => f.friendId != currentUserId).length;
  });
}
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {

      filteredFriends = friends.where((friend) {
        return friend.friendName?.toLowerCase().contains(query)??false;
      }).toList();


      filteredAllUsers = allUsers.where((user) {
        return user.username!.toLowerCase().contains(query);
      }).toList();

    });
  }
  bool updatedOne=false;
  late IO.Socket socket;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: CommonAppBar(title:"Chats" ,isFromHomePage: true,),
      body: BlocBuilder<UserFriendsCubit, UserFriendsState>(
  builder: (context, userListFrntState) {
    if(userListFrntState is UserFriendsLoaded){
      Future.delayed(Duration.zero,(){
        if(updatedOne==false){
          allUsers=userListFrntState.allUsers;
          friends=userListFrntState.friends;
          context.read<CallSocketHandleCubit>().updateFriendsList(friends);
          friendsCount=userListFrntState.friendsCount;
          allUsersCount=userListFrntState.allUsersCount;
          setState(() {
            isLoading=false;
          });
          updatedOne=true;
        }
      });
      return Container(
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
            Padding(
              padding: EdgeInsets.fromLTRB(15, 15, 15, 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Color(0xFF49329A),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF49329A)),
                    hintText: 'Search',
                    hintStyle: TextStyle(fontFamily: 'Poppins Regular'),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            TabBar(
              tabAlignment: TabAlignment.center,
              onTap: (index) {
                setState(() {
                  _searchController.clear();
                  if(index==0){
                    context.read<GetFriendsListCubit>().fetchAllFriends();
                  }
                });
              },
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Color(0xFF49329A),
              labelStyle: TextStyle(
                fontFamily: 'Poppins Regular',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),

              labelPadding: EdgeInsets.only(right: 20), // more breathing room
              tabs: [
                Tab(child: FittedBox(child: Row(
                  children: [
                    Icon(Icons.people,color: Color(0xFF49329A),size: 20,),
                    SizedBox(width: 3,),
                    Text("Friends ($friendsCount)",style: TextStyle(color: Color(0xFF49329A)),),
                  ],
                ))),
                Tab(child: FittedBox(child: Row(
                  children: [
                    Icon(Icons.language,color:Color(0xFF49329A),size: 20,),
                    SizedBox(width: 3,),
                    Text("All Users ($allUsersCount)",style: TextStyle(color: Color(0xFF49329A)),),
                  ],
                ))),
                Tab(child: FittedBox(child: Row(
                  children: [
                    Icon(Icons.call,color:Color(0xFF49329A),size: 20,),
                    SizedBox(width: 3,),
                    Text("Calls",style: TextStyle(color: Color(0xFF49329A)),),
                  ],
                ))),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ChatFriendsTab(),
                  _buildAllUsersTab(),
                  CallLogPage(allUsers: allUsers,),
                ],
              ),
            ),
          ],
        ),
      );
    }else{
      return Center(
        child: CircularProgressIndicator(),
      );
    }

  },
),
    );
  }
  String formatUserCount(int count) => count > 99 ? '99+' : '$count';



  String formatTo12Hour(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr); // parses ISO string
    final formatter = DateFormat('h:mm a'); // 12-hour format
    return formatter.format(dateTime);
  }

 Widget _buildUserRequestTile(BuildContext context, User user) {
  // Determine if request is already sent based on user's status
  bool requestSent = user.chat_request_status == 0 && user.chat_status == "pending";

  return Container(
    margin: EdgeInsets.symmetric(vertical: 8),
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(width: 1, color: Color(0xFFEDE8FF)),
    ),
    child: Row(
      children: [
        _buildUserAvatar(user.avatar_id??0),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username??"",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular',
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        requestSent
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Request Sent',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Poppins Regular',
                    fontSize: 12,
                  ),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      try {
                      final apiService = await ApiService.create();
                      final response = await apiService.sendChatRequest(
                        receiverId: user.id??0,
                      );
                      
                      if (response['status'] == 'success') {
                        setState(() {
                          user.chat_request_status;
                          user.chat_status = "pending";
                        });
                        _updateCounts(); // Update the counts after successful request
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['message'] ?? 'Chat request sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['error'] ?? 
                                         response['message'] ?? 
                                         'Failed to send request'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Center(
                      child: SvgPicture.string(
                        Svgfiles.addUserSvg,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    ),
  );
}



  Future<String> _getCurrentUserAvatar() async {
  try {
    final apiService = await ApiService.create();
    final profile = await apiService.fetchProfileDetails();
    
    if (profile.avatarId == null || profile.avatarId == 0) {
      throw Exception('Using default avatar');
    }
    
    final avatarResponse = await apiService.fetchAvatars();
    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == profile.avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );
    
    return 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
  } catch (e) {
    print('Error fetching current user avatar: $e');
    throw e; // This will trigger the default avatar fallback
  }
}

    Widget _buildUserAvatar(int avatarId) {
    // If avatarId is 0 or null, use default panda image
    if (avatarId == null || avatarId == 0) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFF49329A),
        backgroundImage: AssetImage('assets/avatar2.png'),
      );
    }

    // Otherwise, use network image with the avatar URL
    return FutureBuilder<String>(
      future: _getAvatarUrl(avatarId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: AssetImage('assets/avatar2.png'),
          );
        } else {
          return CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(snapshot.data!),
          );
        }
      },
    );
  }

Future<String> _getAvatarUrl(int avatarId) async {
  try {
    final apiService = await ApiService.create();
    final avatarResponse = await apiService.fetchAvatars();
    
    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );
    
    return 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
  } catch (e) {
    print('Error fetching avatar URL: $e');
    throw e; // This will trigger the error state in FutureBuilder
  }
}

  Widget _buildAllUsersTab() {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final currentUserId = userProvider.userId; // Get current user ID


  List<User> displayUsers = _searchController.text.isEmpty
      ? allUsers
      : allUsers.where((f) => f.username?.toLowerCase().contains(_searchController.text.toLowerCase())??false ).toList();

  if (displayUsers.isEmpty) {
    return Center(
      child: Text(
        _searchController.text.isEmpty
            ? 'No users found'
            : 'No matching users found',
        style: TextStyle(
          fontFamily: 'Poppins Regular',
          color: Colors.grey,
        ),
      ),
    );
  }

  if (isLoading) {
    return Center(child: CircularProgressIndicator());
  } else if (errorMessage.isNotEmpty) {
    return Center(child: Text('Error: $errorMessage'));
  } else {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Scrollbar(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(15, 0, 8, 15),
          itemCount: displayUsers.length,
          itemBuilder: (context, index) {

            return _buildUserRequestTile(context, displayUsers[index]);
          },
        ),
      ),
    );
  }
}

}
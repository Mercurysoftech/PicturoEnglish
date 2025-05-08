import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/responses/allusers_response.dart';
import 'package:picturo_app/responses/friends_response.dart';
import 'package:picturo_app/screens/alluserspage.dart';
import 'package:picturo_app/screens/calllogspage.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart'; // Import your API service

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // List to store fetched users
  List<User> allUsers = [];
  List<Friends> friends = [];
  bool isLoading = true;
  String errorMessage = '';

  int allUsersCount = 0;
  int friendsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllUsers();
  }

  
  Future<void> _fetchAllUsers() async {
    try {
      final apiService = await ApiService.create();
      final UsersResponse response = await apiService.fetchAllUsers(); 
      final FriendsResponse friendsResponse = await apiService.fetchFriends();
      setState(() {
        allUsers = response.data;
        friends = friendsResponse.data;
         allUsersCount = allUsers.length;

         // Filter out current user from friends count
        final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;
        friendsCount = friends.where((f) => f.friend_id != currentUserId).length;

        isLoading = false; 
       

      });
      print('All Users: $allUsers'); // Debugging line
    } catch (e) {
      setState(() {
        errorMessage = e.toString(); 
        isLoading = false; 
      });
    }
  }

  void _updateCounts() {
  final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;
  setState(() {
    allUsersCount = allUsers.length;
    friendsCount = friends.where((f) => f.friend_id != currentUserId).length;
  });
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), 
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF49329A),
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0), 
            child: Row(
              children: [
                Text(
                  'Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
actions: [
  Padding(
    padding: const EdgeInsets.only(top: 10.0, right: 24.0),
    child: FutureBuilder(
      future: _getCurrentUserAvatar(),
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
        }
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyProfileScreen()),
            );
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: snapshot.hasData
                ? NetworkImage(snapshot.data.toString())
                : AssetImage('assets/avatar2.png') as ImageProvider,
          ),
        );
      },
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
      body: Container(
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
              labelStyle: TextStyle(fontFamily: 'Poppins Regular',fontWeight: FontWeight.bold),
              controller: _tabController,
              indicatorColor: Color(0xFF49329A),
              tabs: [
                Tab(text: "Friends ($friendsCount)"),
                Tab(text: "All Users ($allUsersCount)"),
                Tab(text: "Calls"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatlist(),
                  _buildAllUsersTab(),
                  CallLogsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUserTile(BuildContext context, User user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen( profileId: user.avatar_id, 
            userName: user.username,   
            userId: user.id,           
          ),
          ),
        );
      },
      child: 
      Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(width: 1, color: Color(0xFFDDDDDD))),
        child: Row(
          children: [
             _buildUserAvatar(user.avatar_id),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Regular'),
                  ),
                  Text(
                    'Communicate with your buddy',
                    style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Poppins Regular',
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, Friends user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen( profileId: user.friend_profile_pic, 
            userName: user.friend_name,   
            userId: user.friend_id,           
          ),
          ),
        );
      },
      child: 
      Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(width: 1, color: Color(0xFFDDDDDD))),
        child: Row(
          children: [
             _buildUserAvatar(user.friend_profile_pic),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.friend_name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Regular'),
                  ),
                  Text(
                    'Communicate with your buddy',
                    style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Poppins Regular',
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        _buildUserAvatar(user.avatar_id),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
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
                        receiverId: user.id,
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

 Widget _buildChatlist() {
  if (isLoading) {
    return Center(child: CircularProgressIndicator());
  } else if (errorMessage.isNotEmpty) {
    return Center(child: Text('Error: $errorMessage'));
  } else if (friends.isEmpty) {
    return Center(
      child: Text(
        'No friends yet',
        style: TextStyle(
          fontFamily: 'Poppins Regular',
          color: Colors.grey,
        ),
      ),
    );
  }

  final currentUserId = Provider.of<UserProvider>(context).userId;
  print('Current User ID: $currentUserId');
  print('Friends List: $friends');

  // Filter out the current user from the friends list
  List<Friends> filteredFriends = friends
      .where((friend) => friend.friend_id != currentUserId)
      .toList();

  return RefreshIndicator(
    onRefresh: _fetchAllUsers, // Allow pull-to-refresh
    child: ListView(
      padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
      children: [
        SizedBox(height: 20),
        ...filteredFriends.map((friend) => _buildFriendTile(context, friend)),
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


  if (isLoading) {
    return Center(child: CircularProgressIndicator());
  } else if (errorMessage.isNotEmpty) {
    return Center(child: Text('Error: $errorMessage'));
  } else {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
      itemCount: allUsers.length,
      itemBuilder: (context, index) {
        print('Users: ${allUsers[index]}');
        return _buildUserRequestTile(context, allUsers[index]);
      },
    );
  }
}

}
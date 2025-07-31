import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:picturo_app/cubits/call_cubit/get_friends_list_cubit/get_friends_list_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responses/friends_response.dart';
import '../../services/api_service.dart';
import '../chatscreenpage.dart';
class ChatFriendsTab extends StatefulWidget {
  const ChatFriendsTab({super.key});

  @override
  State<ChatFriendsTab> createState() => _ChatFriendsTabState();
}

class _ChatFriendsTabState extends State<ChatFriendsTab> {
  Future<void> _fetchAllUsers()async{
    context.read<GetFriendsListCubit>().fetchAllFriends();
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetFriendsListCubit, GetFriendsListState>(
  builder: (context, state) {
    if(state is GetFriendsListLoaded){
      List<Friends> friends=state.friends;
      return RefreshIndicator(
        onRefresh: _fetchAllUsers, // Allow pull-to-refresh
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            children: [
              const SizedBox(height: 20),
              for (int i = 0; i < friends.length; i++)
                _buildFriendTile(context, friends[i], i),
            ],
          ),
        ),
      );
    }else{
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(),
      );
    }

  },
);
  }

  Widget _buildFriendTile(BuildContext context, Friends user,int index) {

    return GestureDetector(
      onTap: () async{
        SharedPreferences preferences=await SharedPreferences.getInstance();
        List<String>? countViewedIndex=preferences.getStringList("Count_Viewed_Index");
        countViewedIndex?.add("${index}");
        preferences.setStringList("Count_Viewed_Index",countViewedIndex??[]);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              friendDetails: user,
              avatarWidget: _buildUserAvatar(user.friendProfilePic??0),
              userName: user.friendName??'',
              userId: user.friendId??0,
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
            _buildUserAvatar(user.friendProfilePic??0),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.friendName??'',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins Regular'),
                      ),
                      Text(
                        (user.lastMessageTime==null)?"":formatTo12Hour(user.lastMessageTime??''),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins Regular'),
                      ),
                    ],
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (user.lastMessage==null)?SizedBox():Text(
                        '${user.lastMessage}',
                        style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins Regular',
                            fontSize: 12),
                      ),
                      (user.unreadCount==0)?SizedBox():Container(
                        padding: EdgeInsets.symmetric(horizontal: 9,vertical: 3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Color(0xFF49329A)
                        ),
                        child: Center(
                          child: Text("${user.unreadCount}",style: TextStyle(color: Colors.white),),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTo12Hour(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr); // parses ISO string
    final formatter = DateFormat('h:mm a'); // 12-hour format
    return formatter.format(dateTime);
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
}

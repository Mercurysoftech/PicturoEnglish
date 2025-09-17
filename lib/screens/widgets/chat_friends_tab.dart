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
  Map<int, String> _avatarCache = {};


  
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
      return const Center(
  child: SizedBox(
    height: 24,
    width: 24,
    child: CircularProgressIndicator(strokeWidth: 2),
  ),
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
        
final shouldRefresh = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        avatarWidget: _buildUserAvatar(user.friendProfilePic ?? 0),
        userName: user.friendName ?? '',
        userId: user.friendId ?? 0,
        profilePicId: user.friendProfilePic ?? 0,
      ),
    ),
  );

  if (shouldRefresh == true) {
    context.read<GetFriendsListCubit>().fetchAllFriends();
  }
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
    final formatter = DateFormat('h:mm a'); 
    return formatter.format(dateTime);
  }

Widget _buildUserAvatar(int avatarId) {
  if (avatarId == 0) {
    return CircleAvatar(
      radius: 25,
      backgroundImage: AssetImage('assets/avatar2.png'),
    );
  }

  if (_avatarCache.containsKey(avatarId)) {
    // ✅ Instant load if cached
    return CircleAvatar(
      radius: 25,
      backgroundImage: NetworkImage(_avatarCache[avatarId]!),
    );
  }

  // Fetch once if not cached
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
  if (_avatarCache.containsKey(avatarId)) {
    return _avatarCache[avatarId]!;
  }

  try {
    final apiService = await ApiService.create();
    final avatarResponse = await apiService.fetchAvatars();

    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );

    final url = 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
    _avatarCache[avatarId] = url; // ✅ Save in cache
    return url;
  } catch (e) {
    print('Error fetching avatar URL: $e');
    throw e;
  }
}

}

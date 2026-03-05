import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:picturo_app/classes/helper/avatar_cache_manager.dart';
import 'package:picturo_app/cubits/call_cubit/get_friends_list_cubit/get_friends_list_cubit.dart';
import 'package:picturo_app/utils/common_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responses/friends_response.dart';
import '../../services/api_service.dart';
import '../chatscreenpage.dart';

class ChatFriendsTab extends StatefulWidget {

  const ChatFriendsTab({
    super.key});

  @override
  State<ChatFriendsTab> createState() => _ChatFriendsTabState();
}

class _ChatFriendsTabState extends State<ChatFriendsTab> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    // Preload avatars for instant display
    _preloadAvatars();
  }

  Future<void> _preloadAvatars() async {
    await AvatarCacheManager().preloadAvatars();
  }

  Future<void> _fetchAllUsers() async {
    context.read<GetFriendsListCubit>().fetchAllFriends(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return BlocBuilder<GetFriendsListCubit, GetFriendsListState>(
  builder: (context, state) {
    if (state is GetFriendsListLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (state is GetFriendsListLoaded) {
      final friends = state.friends;

      if (friends.isEmpty) {
        return const EmptyFriendsState();
      }

      return RefreshIndicator(
        onRefresh: () {
          return context
              .read<GetFriendsListCubit>()
              .fetchAllFriends(forceRefresh: true);
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          itemCount: friends.length,
          itemBuilder: (context, i) {
            return _buildFriendTile(context, friends[i], i);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  },
);

  }

  Widget _buildFriendTile(BuildContext context, Friends user, int index) {
    return GestureDetector(
      onTap: () async {
        SharedPreferences preferences = await SharedPreferences.getInstance();
        List<String>? countViewedIndex = 
            preferences.getStringList("Count_Viewed_Index");
        countViewedIndex?.add("$index");
        preferences.setStringList("Count_Viewed_Index", countViewedIndex ?? []);

        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              avatarWidget: CachedAvatarWidget(
                avatarId: user.friendProfilePic ?? 0,
              ),
              userName: user.friendName ?? '',
              userId: user.friendId ?? 0,
              profilePicId: user.friendProfilePic ?? 0,
            ),
          ),
        );

        if (shouldRefresh == true) {
          context.read<GetFriendsListCubit>().fetchAllFriends(forceRefresh: true);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(width: 1, color: Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            // Use cached avatar widget
            CachedAvatarWidget(
              avatarId: user.friendProfilePic ?? 0,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.friendName ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins Regular',
                        ),
                      ),
                      Text(
                        (user.lastMessageTime == null)
                            ? ""
                            : formatTo12Hour(user.lastMessageTime ?? ''),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Poppins Regular',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (user.lastMessage == null)
                          ? SizedBox()
                          : Expanded(
                              child: Text(
                                '${user.lastMessage}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Poppins Regular',
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      (user.unreadCount == 0)
                          ? SizedBox()
                          : Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Color(0xFF49329A),
                              ),
                              child: Center(
                                child: Text(
                                  "${user.unreadCount}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
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
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final formatter = DateFormat('h:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return '';
    }
  }
}


class EmptyFriendsState extends StatelessWidget {
  const EmptyFriendsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/Contact.json',
            width: 230,
            height: 230,
            fit: BoxFit.contain,
            repeat: true,
          ),
          const Text(
            "You don’t have any friends yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.commonFont
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Once you add friends, they’ll show up here",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontFamily: AppConstants.commonFont
            ),
          ),
        ],
      ),
    );
  }
}



import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responses/allusers_response.dart';
import '../../responses/friends_response.dart';
import '../../services/api_service.dart';


part 'user_friends_state.dart';

class UserFriendsCubit extends Cubit<UserFriendsState> {
  UserFriendsCubit() : super(UserFriendsInitial());

  Future<void> fetchAllUsersAndFriends() async {
    (state is UserFriendsInitial)?emit(UserFriendsLoading()):null;
    try {
      final apiService = await ApiService.create();
      final usersResponse = await apiService.fetchAllUsers();
      final friendsResponse = await apiService.fetchFriends();

      final List<User> allUsers = usersResponse.data;
      final List<Friends> friends = friendsResponse.data;

      final int allUsersCount = allUsers.length;
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final int friendsCount = friends
          .where((f) => f.friendId.toString() != currentUserId.toString())
          .length;

      emit(UserFriendsLoaded(
        allUsers: allUsers,
        friends: friends,
        allUsersCount: allUsersCount,
        friendsCount: friendsCount,
      ));
    } catch (e) {
      emit(UserFriendsError(e.toString()));
    }
  }
  void resetCubit(){
    emit(UserFriendsInitial());
  }
}

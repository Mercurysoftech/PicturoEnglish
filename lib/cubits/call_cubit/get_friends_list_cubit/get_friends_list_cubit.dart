import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../responses/friends_response.dart';
import '../../../services/api_service.dart';

part 'get_friends_list_state.dart';

class GetFriendsListCubit extends Cubit<GetFriendsListState> {
  GetFriendsListCubit() : super(GetFriendsListInitial());
  Future<void> fetchAllFriends() async {
    (state is GetFriendsListInitial)?emit(GetFriendsListLoading()):null;
    try {
      final apiService = await ApiService.create();
      final friendsResponse = await apiService.fetchFriends();


      final List<Friends> friends = friendsResponse.data;

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      // final int friendsCount = friends
      //     .where((f) => f.friendId.toString() != currentUserId.toString())
      //     .length;
      log("sdjcksdjcnksjcnskdcj ${friends}");

      emit(GetFriendsListLoaded(friends: friends
      ));
    } catch (e) {
      emit(GetFriendsListFailed());
    }
  }
  void resetCubit(){
    emit(GetFriendsListFailed());
  }
}

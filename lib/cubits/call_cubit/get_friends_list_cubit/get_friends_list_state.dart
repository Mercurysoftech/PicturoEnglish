part of 'get_friends_list_cubit.dart';

sealed class GetFriendsListState extends Equatable {
  const GetFriendsListState();
}

final class GetFriendsListInitial extends GetFriendsListState {
  @override
  List<Object> get props => [];
}
final class GetFriendsListLoading extends GetFriendsListState {
  @override
  List<Object> get props => [];
}
final class GetFriendsListLoaded extends GetFriendsListState {
  const GetFriendsListLoaded({required this.friends});
  final List<Friends> friends;
  
  @override
  List<Object> get props => [friends];
}
final class GetFriendsListFailed extends GetFriendsListState {
  @override
  List<Object> get props => [];
}

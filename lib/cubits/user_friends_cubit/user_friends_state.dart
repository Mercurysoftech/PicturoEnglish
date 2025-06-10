part of 'user_friends_cubit.dart';

abstract class UserFriendsState extends Equatable {
  const UserFriendsState();

  @override
  List<Object?> get props => [];
}

class UserFriendsInitial extends UserFriendsState {}

class UserFriendsLoading extends UserFriendsState {}

class UserFriendsLoaded extends UserFriendsState {
  final List<User> allUsers;
  final List<Friends> friends;
  final int allUsersCount;
  final int friendsCount;

  const UserFriendsLoaded({
    required this.allUsers,
    required this.friends,
    required this.allUsersCount,
    required this.friendsCount,
  });

  @override
  List<Object?> get props => [allUsers, friends, allUsersCount, friendsCount];
}

class UserFriendsError extends UserFriendsState {
  final String message;

  const UserFriendsError(this.message);

  @override
  List<Object?> get props => [message];
}

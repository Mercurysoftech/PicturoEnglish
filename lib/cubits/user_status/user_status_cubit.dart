import 'package:flutter_bloc/flutter_bloc.dart';

class UserStatusCubit extends Cubit<Map<String, bool>> {
  UserStatusCubit() : super({});

  void setUserStatus(String userId, bool isOnline) {
    final updated = Map<String, bool>.from(state);
    updated[userId] = isOnline;
    emit(updated);
  }

  bool isUserOnline(String userId) {
    return state[userId] ?? false;
  }
}

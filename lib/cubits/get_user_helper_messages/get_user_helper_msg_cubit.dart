import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


part 'get_user_helper_msg_state.dart';

class UserSupportCubit extends Cubit<UserSupportState> {
  UserSupportCubit() : super(UserSupportInitial());

  Future<void> fetchUserSupport() async {
    (state is UserSupportLoaded)?null:emit(UserSupportLoading());
    final List<Map<String, String>> messages = [];
    final url = Uri.parse("http://picturoenglish.com/api/get_user_support.php");
    SharedPreferences pref =await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    String? userId = pref.getString("user_id");

    // try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<UserSupport> supports = List<UserSupport>.from(
          data['data'].map((item) =>UserSupport.fromJson(item)),
        );


          for (var element in supports.first.messages) {

            messages.add({
              'message': element.message,
              'isMe': element.type=='user'?"true":'false',
              'time': formatToAmPm(element.createdAt),
            });
          }


        emit(UserSupportLoaded(messages));
      } else {
        emit(UserSupportError('Failed to load data'));
      }
    // } catch (e) {
    //   emit(UserSupportError(e.toString()));
    // }
  }
  String formatToAmPm(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }
}

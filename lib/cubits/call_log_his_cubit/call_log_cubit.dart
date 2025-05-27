import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/call_log_model.dart';
import '../../responses/allusers_response.dart';

part 'call_log_state.dart';

class CallLogCubit extends Cubit<CallLogState> {
  CallLogCubit() : super(CallLogInitial());

  Future<void> fetchCallLogs({required List<User> allUsers}) async {
    emit(CallLogLoading());
    try {
      SharedPreferences pref =await SharedPreferences.getInstance();
      String? token = pref.getString("auth_token");
      final response = await http.get(
        Uri.parse('https://picturoenglish.com/api/call_log_list.php'),
        headers: {
          'Accept': 'application/json',
          "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJsb2NhbGhvc3QiLCJ1c2VyX2lkIjoxNDksInVzZXJuYW1lIjoibmlzYXIifQ.LNwVgSSrV_ZLYK2sVYC2259cXyrrlFkG5uLoKZNCQkE",
        },
      );

      final data = json.decode(response.body);
      print("sdkcskjcnsdkc ${response.body}");

      if (data['status'] == true) {
        List<CallLog> logs = (data['data'] as List)
            .map((item) => CallLog.fromJson(item))
            .toList();
        emit(CallLogLoaded(logs));
      } else {
        emit(CallLogError('Failed to load call logs.'));
      }
    } catch (e) {
      emit(CallLogError('Error: $e'));
    }
  }
}

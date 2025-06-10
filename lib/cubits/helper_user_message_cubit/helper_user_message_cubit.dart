import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
part 'helper_user_message_state.dart';

class HelperUserMessageCubit extends Cubit<HelperUserMessageState> {
  HelperUserMessageCubit() : super(HelperUserMessageInitial());
  Future<void> sendUserMessage(String userMessage) async {
    emit(HelperUserMessageLoading());
    try {
      SharedPreferences pref =await SharedPreferences.getInstance();
      String? token = pref.getString("auth_token");
      final url = Uri.parse('http://picturoenglish.com/api/user-message.php');
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json'},
        body: json.encode({'user_message': userMessage}),
      );

      final data = json.decode(response.body);

      if (data['status'] == true) {
        Fluttertoast.showToast(msg: "Your Message Send to Admin , Please Wait for Admin Response");
        emit(HelperUserMessageLoaded());
      } else {
        Fluttertoast.showToast(msg: "${data['error']}",backgroundColor: Colors.red);
        emit(HelperUserMessageFailed());
      }
    } catch (e) {
      emit(HelperUserMessageFailed());
    }
  }
}

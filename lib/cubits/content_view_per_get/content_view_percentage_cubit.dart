import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

part 'content_view_percentage_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit() : super(ProgressLoading());

  Future<void> fetchProgress({
    required int bookId,
    required int topicId,
    required bool isFromTopic,
  }) async {

    emit(ProgressLoading());

    final url = Uri.parse("https://picturoenglish.com/api/getprogress_percentage.php");
    final body = {
      "book_id": bookId,
      "topic_id": topicId,
    };

    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString("auth_token");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final int totalQuestions = data['total_questions'];
          final int readQuestions = data['read_questions'];
          double progress = totalQuestions > 0 ? readQuestions / totalQuestions : 0.0;

           if(progress==1&&isFromTopic){
             Fluttertoast.showToast(msg: "Content was Completed Successfully",backgroundColor: Colors.green);
           }
          emit(ProgressLoaded(progress));
        } else {
          emit(ProgressFailed("Failed to fetch progress"));
        }
      } else {
        emit(ProgressFailed("Server error: ${response.statusCode}"));
      }
    } catch (e) {
      emit(ProgressFailed("Error: $e"));
    }
  }
}

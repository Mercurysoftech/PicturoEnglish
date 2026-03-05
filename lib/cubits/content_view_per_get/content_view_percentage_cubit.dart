// content_view_percentage_cubit.dart
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

    final url =
        Uri.parse("https://picturoenglish.com/api/getprogress_percentage.php");
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
          final bool isFreehitUser = data['isfreehituser'] ?? false;
          final bool isSubscribePlan = data['issubscribeplan'] ?? false;
          final int actualProgress = data['actual_progress'] ?? 0;
          final int allowedProgress = data['allowed_progress'] ?? 0;

          // double progress =
          //     totalQuestions > 0 ? readQuestions / totalQuestions : 0.0;
          final double progress =
              (data['progress_ratio'] as num?)?.toDouble() ?? 0.0;

          log("Progress: $progress");
          log("Actual Progress: $actualProgress");
          log("Total Questions: $totalQuestions, Read Questions: $readQuestions");
          log("Is Free User: $isFreehitUser, Is Subscribed: $isSubscribePlan");
          log("Actual Progress: $actualProgress, Allowed Progress: $allowedProgress");

          // Check if should show subscription dialog
          final bool shouldShowSubscriptionDialog =
              isFreehitUser && !isSubscribePlan;

          final bool isCompleted = progress >= 1.0 && isFromTopic;
          if (progress >= 1.0 && isFromTopic) {
            Fluttertoast.showToast(
                msg: "Content was Completed Successfully",
                backgroundColor: Colors.green);
          }

          emit(ProgressLoaded(
            progress,
            shouldShowSubscriptionDialog: shouldShowSubscriptionDialog,
            isFreehitUser: isFreehitUser,
            isSubscribePlan: isSubscribePlan,
            actualProgress: actualProgress,
            allowedProgress: allowedProgress,
          ));
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

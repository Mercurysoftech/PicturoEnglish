import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
part 'call_duration_handle_state.dart';

class CallTimerCubit extends Cubit<CallTimerState> {
  Timer? _timer;
  bool _isPaused = false;

  CallTimerCubit() : super(const CallTimerState());

  void startTimer() {
    _timer?.cancel();
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        emit(state.copyWith(duration: state.duration + const Duration(seconds: 1)));
      }
    });
  }

  void pauseTimer() {
    _isPaused = true;
  }

  void resumeTimer() {
    _isPaused = false;
  }

  void stopTimer({
    required String receiverId,
    required String callType,
    required String status,

  }) {
    postCallLog(duration: state.duration.inMinutes,
        status: status,
        receiverId: receiverId,
        callType: callType);
    _timer?.cancel();
  }

  void resetTimer() {
    _timer?.cancel();
    _isPaused = false;
    emit(const CallTimerState(duration: Duration.zero));
  }
  Future<void> postCallLog({
    required String receiverId,
    required String callType,
    required String status,
    required int duration,
  }) async {
    final url = Uri.parse('https://picturoenglish.com/api/call_log_add.php');
    SharedPreferences pref =await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    final body = {
      'receiver_id': receiverId,
      'call_type': callType,
      'status': "completed",
      'duration': duration,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );
      print('Call log added successfully: ${response.body} __ ${body}');
      if (response.statusCode == 200) {

      } else {
        print('Failed to add call log. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error posting call log: $e');
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

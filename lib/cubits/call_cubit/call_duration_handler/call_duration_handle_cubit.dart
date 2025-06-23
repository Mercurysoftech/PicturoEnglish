import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  void stopTimer() {
    _timer?.cancel();
  }

  void resetTimer() {
    _timer?.cancel();
    _isPaused = false;
    emit(const CallTimerState(duration: Duration.zero));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

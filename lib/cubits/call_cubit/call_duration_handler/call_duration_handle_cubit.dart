import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'call_duration_handle_state.dart';

class CallTimerCubit extends Cubit<CallTimerState> {
  Timer? _timer;

  CallTimerCubit() : super(const CallTimerState());

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      emit(state.copyWith(duration: state.duration + const Duration(seconds: 1)));
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void resetTimer() {
    _timer?.cancel();
    emit(const CallTimerState(duration: Duration.zero));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

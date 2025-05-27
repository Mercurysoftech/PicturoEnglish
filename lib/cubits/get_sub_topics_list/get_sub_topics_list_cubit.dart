import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../responses/questions_response.dart';
import '../../services/api_service.dart';
part 'get_sub_topics_list_state.dart';
// subtopic_cubit.dart


class SubtopicCubit extends Cubit<SubtopicState> {
  SubtopicCubit() : super(SubtopicInitial());

  Future<void> fetchQuestions(int topicId) async {
    emit(SubtopicLoading());
    try {
      final apiService = await ApiService.create();
      final response = await apiService.fetchQuestions(topicId);

      if (response.status == 'success') {
        emit(SubtopicLoaded(response.questions ?? []));
      } else {
        emit(SubtopicError(response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(SubtopicError("Error fetching questions: ${e.toString()}"));
    }
  }
}

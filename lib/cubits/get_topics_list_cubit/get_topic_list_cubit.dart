import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_service.dart';

part 'get_topic_list_state.dart';

class TopicCubit extends Cubit<TopicState> {
  TopicCubit() : super(TopicLoading());

  Future<void> fetchTopics(int topicId) async {
    // emit(TopicLoading());
    // try {
      final apiService = await ApiService.create();
      final topicsResponse = await apiService.fetchTopics(topicId);

      final topics = topicsResponse.data.map((topic) {
        return {
          'title': topic.topicsName,
          'id': topic.id,
          'image': topic.topicsImage,
        };
      }).toList();

      emit(TopicLoaded(topics));
    // } catch (e) {
    //   emit(TopicError("Error fetching topics: $e"));
    // }
  }
}
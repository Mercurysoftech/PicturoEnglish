import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picturo_app/cubits/content_view_per_get/content_view_percentage_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../responses/questions_response.dart';
import '../../services/api_service.dart';
part 'get_sub_topics_list_state.dart';

class SubtopicCubit extends Cubit<SubtopicState> {
  SubtopicCubit() : super(SubtopicInitial());

  Future<void> fetchQuestions(int topicId) async {
    emit(SubtopicLoading());
    try {
      // Pass topicId to get topic-specific cache
      final localResponse =
          await LocalStorageHelper.getQuestionsResponse(topicId);
      if (localResponse != null &&
          localResponse.questions?.isNotEmpty == true) {
        emit(SubtopicLoaded(localResponse.questions!));
        debugPrint('Loaded Sub Topics from Local Storage for topic $topicId ✅');
        return;
      }

      final apiService = await ApiService.create();
      final response = await apiService.fetchQuestions(topicId);

      if (response.status == 'success') {
        debugPrint('Sub Topics Loaded from API for topic $topicId ✅');

        // Create a new list with updated images
        final updatedQuestions = <Question>[];
        for (var q in response.questions!) {
          if (q.qusImage != null && q.qusImage!.isNotEmpty) {
            final localPath = await downloadAndSaveImage(q.qusImage!);
            updatedQuestions.add(Question(
              id: q.id,
              topicId: q.topicId,
              question: q.question,
              meaning: q.meaning,
              example: q.example,
              qusImage: localPath ?? q.qusImage,
              read: q.read ?? false, // Ensure default value
            ));
          } else {
            updatedQuestions.add(Question(
              id: q.id,
              topicId: q.topicId,
              question: q.question,
              meaning: q.meaning,
              example: q.example,
              qusImage: q.qusImage,
              read: q.read ?? false, // Ensure default value
            ));
          }
        }

        // Create new response with updated questions
        final updatedResponse = QuestionsResponse(
          status: response.status,
          message: response.message,
          questions: updatedQuestions,
        );

        // Save with topicId
        await LocalStorageHelper.saveQuestionsResponse(
            updatedResponse, topicId);
        emit(SubtopicLoaded(updatedQuestions));
      } else {
        emit(SubtopicError(response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(SubtopicError("Error fetching questions: ${e.toString()}"));
    }
  }

  Future<void> markQuestionAsRead(
  BuildContext context,
  int questionId,
  int topicId,
  int bookId,
) async {
  final currentState = state;
  if (currentState is SubtopicLoaded) {

    // Sync to backend
    try {
      final apiService = await ApiService.create();
      await apiService.readMarkAsRead(
        bookId: bookId.toString(),
        topicId: topicId.toString(),
        questionId: questionId.toString(),
      );
    } catch (e) {
      debugPrint("Sync failed: $e");
    }

    // Local Update
    final updatedQuestions = currentState.questions.map((q) {
      return q.id == questionId ? q.copyWith(read: true) : q;
    }).toList();

    await LocalStorageHelper.saveQuestionsResponse(
      QuestionsResponse(
        status: 'success',
        message: 'Updated',
        questions: updatedQuestions,
      ),
      topicId,
    );

    emit(SubtopicLoaded(updatedQuestions));

    // Refresh progress
    context.read<ProgressCubit>().fetchProgress(
      isFromTopic: true,
      bookId: bookId,
      topicId: topicId,
    );
  }
}


  Future<String?> downloadAndSaveImage(String imageUrl) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        debugPrint('Storage permission denied ❌');
        return null;
      }

      final response = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/gh/Mercurysoftech/PicturoEnglish@main/images_app/$imageUrl'));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Image saved: $filePath');
        return filePath;
      } else {
        debugPrint('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }
}

class LocalStorageHelper {
  static String _getQuestionsKey(int topicId) =>
      'questions_cache_topic_$topicId';

  /// Save response as JSON String for specific topic
  static Future<void> saveQuestionsResponse(
      QuestionsResponse response, int topicId) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert to JSON
    final jsonString = jsonEncode({
      'status': response.status,
      'message': response.message,
      'questions': response.questions
          ?.map((q) => {
                'id': q.id,
                'topic_id': q.topicId,
                'question': q.question,
                'meaning': q.meaning,
                'example': q.example,
                'qus_image': q.qusImage,
                'read': q.read,
              })
          .toList(),
    });

    await prefs.setString(_getQuestionsKey(topicId), jsonString);
  }

  /// Retrieve cached response for specific topic
  static Future<QuestionsResponse?> getQuestionsResponse(int topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getQuestionsKey(topicId));
    if (jsonString == null) return null;

    final jsonMap = jsonDecode(jsonString);
    return QuestionsResponse.fromJson(jsonMap);
  }

  /// Clear cache for specific topic
  static Future<void> clearQuestionsCache(int topicId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getQuestionsKey(topicId));
  }

  /// Clear all topics cache
  static Future<void> clearAllQuestionsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('questions_cache_topic_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

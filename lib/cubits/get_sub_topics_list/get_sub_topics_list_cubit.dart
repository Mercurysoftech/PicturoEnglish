// get_sub_topics_list_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
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
  
  static bool _permissionChecked = false;
  static bool _hasPermission = false;

  Future<void> fetchQuestions(int topicId) async {
    emit(SubtopicLoading());
    
    try {
      if (!_permissionChecked) {
        await _checkStoragePermission();
      }

      // Check local cache first
      final localResponse = await LocalStorageHelper.getQuestionsResponse(topicId);
      
      if (localResponse != null && localResponse.questions?.isNotEmpty == true) {
        // Don't validate cache - just use it and let image widget handle fallback
        emit(SubtopicLoaded(localResponse.questions!));
        debugPrint('✅ Loaded Sub Topics from Local Storage for topic $topicId');
        return;
      }

      // Fetch from API
      final apiService = await ApiService.create();
      final response = await apiService.fetchQuestions(topicId).timeout(
        const Duration(seconds: 12),
      );

      if (response.status == 'success' && response.questions != null) {
        debugPrint('🔥 Sub Topics Loaded from API for topic $topicId');
        
        final totalCount = response.questions!.length;
        final loadedQuestions = <Question>[];

        // Process questions
        for (var i = 0; i < response.questions!.length; i++) {
          final q = response.questions![i];
          String? finalImagePath = q.qusImage;
          
          // Try to download images if we have permission
          if (q.qusImage != null && q.qusImage!.isNotEmpty && _hasPermission) {
            bool isRemote = q.qusImage!.startsWith('http') ||
                q.qusImage!.startsWith('uploads/');
            
            if (isRemote) {
              try {
                final downloaded = await downloadAndSaveImage(q.qusImage!);
                if (downloaded != null) {
                  finalImagePath = downloaded;
                  debugPrint('✅ Downloaded: ${q.question}');
                }
              } catch (e) {
                debugPrint('⚠️ Download skipped for ${q.question}: $e');
                // Keep original remote path as fallback
              }
            }
          }
          
          final updatedQuestion = Question(
            id: q.id,
            topicId: q.topicId,
            question: q.question,
            meaning: q.meaning,
            example: q.example,
            qusImage: finalImagePath,
            read: q.read ?? false,
          );

          loadedQuestions.add(updatedQuestion);
          
          // Emit progressive state every 3 items or at the end
          if ((i + 1) % 3 == 0 || i == response.questions!.length - 1) {
            emit(SubtopicProgressiveLoading(
              loadedQuestions: List.from(loadedQuestions),
              totalCount: totalCount,
            ));
          }
        }

        // Save to cache
        final finalResponse = QuestionsResponse(
          status: response.status,
          message: response.message,
          questions: loadedQuestions,
        );
        
        await LocalStorageHelper.saveQuestionsResponse(finalResponse, topicId);
        
        // Emit final loaded state
        emit(SubtopicLoaded(loadedQuestions));
        
      } else {
        emit(SubtopicError(response.message ?? 'Unknown error'));
      }
    } on TimeoutException {
      emit(SubtopicError(
        "Taking longer than expected. Please check your internet.",
      ));
    } catch (e) {
      debugPrint('❌ Error in fetchQuestions: $e');
      emit(SubtopicError("Error fetching questions: ${e.toString()}"));
    }
  }

  Future<void> _checkStoragePermission() async {
    if (_permissionChecked) return;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      _hasPermission = true;
      debugPrint('✅ Storage access available: ${dir.path}');
    } catch (e) {
      debugPrint('⚠️ Storage access error: $e');
      _hasPermission = false;
    }
    
    _permissionChecked = true;
  }

  Future<void> markQuestionAsRead(
    BuildContext context,
    int questionId,
    int topicId,
    int bookId,
  ) async {
    final currentState = state;
    
    if (currentState is SubtopicLoaded) {
      // Optimistically update UI first
      final updatedQuestions = currentState.questions.map((q) {
        return q.id == questionId ? q.copyWith(read: true) : q;
      }).toList();

      emit(SubtopicLoaded(updatedQuestions));

      // Save to local cache immediately
      await LocalStorageHelper.saveQuestionsResponse(
        QuestionsResponse(
          status: 'success',
          message: 'Updated',
          questions: updatedQuestions,
        ),
        topicId,
      );

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

      // Refresh progress for this topic
      try {
        await context.read<ProgressCubit>().fetchProgress(
          isFromTopic: true,
          bookId: bookId,
          topicId: topicId,
        );
      } catch (e) {
        debugPrint("Progress refresh failed: $e");
      }
    }
  }

  Future<void> forceClearAndRefetch(int topicId) async {
    debugPrint('🗑️ Force clearing cache for topic $topicId');
    await LocalStorageHelper.clearQuestionsCache(topicId);
    await fetchQuestions(topicId);
  }

  Future<String?> downloadAndSaveImage(String imageUrl) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      String fullUrl = imageUrl;
      if (!imageUrl.startsWith('http')) {
        fullUrl = 'https://picturoenglish.com/admin/$imageUrl';
      }

      final fileName = imageUrl
          .split('/')
          .last
          .replaceAll(RegExp(r'[^\w\.-]'), '_');
      final filePath = '${directory.path}/images/$fileName';
      
      final imagesDir = Directory('${directory.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final file = File(filePath);
      
      if (await file.exists()) {
        return filePath;
      }

      final response = await http.get(Uri.parse(fullUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('💾 Image saved: $fileName');
        return filePath;
      } else {
        debugPrint('❌ Download failed: HTTP ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      debugPrint('⏱️ Download timeout');
      return null;
    } catch (e) {
      debugPrint('❌ Error downloading: $e');
      return null;
    }
  }
}

class LocalStorageHelper {
  static String _getQuestionsKey(int topicId) => 'questions_cache_topic_$topicId';

  static Future<void> saveQuestionsResponse(
    QuestionsResponse response,
    int topicId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode({
      'status': response.status,
      'message': response.message,
      'questions': response.questions?.map((q) => {
        'id': q.id,
        'topic_id': q.topicId,
        'question': q.question,
        'meaning': q.meaning,
        'example': q.example,
        'qus_image': q.qusImage,
        'read': q.read,
      }).toList(),
    });

    await prefs.setString(_getQuestionsKey(topicId), jsonString);
  }

  static Future<QuestionsResponse?> getQuestionsResponse(int topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getQuestionsKey(topicId));
    if (jsonString == null) return null;

    final jsonMap = jsonDecode(jsonString);
    return QuestionsResponse.fromJson(jsonMap);
  }

  static Future<void> clearQuestionsCache(int topicId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getQuestionsKey(topicId));
  }

  static Future<void> clearAllQuestionsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('questions_cache_topic_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
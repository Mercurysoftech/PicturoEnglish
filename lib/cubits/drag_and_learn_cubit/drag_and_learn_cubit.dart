import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

import '../../models/dragand_learn_model.dart';
import '../../services/api_service.dart';
part 'drag_and_learn_state.dart';

class DragLearnCubit extends Cubit<DragLearnState> {
  DragLearnCubit() : super(DragLearnLoading());

  Future<void> fetchDragLearnData({
    required int bookId,
    bool? isLoading,
    int? levelFrom,
  }) async {
    (isLoading != null && isLoading) ? null : emit(DragLearnLoading());

    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");

    final localData = await DragLearnLocalHelper.getFromLocal();
    int savedLevel = pref.getInt("DragAndLearnQuestLevel") ?? 0;

    if (localData != null && localData.data?.isNotEmpty == true) {
      emit(DragLearnLoaded(localData, savedLevel));
      debugPrint("Loaded Drag & Learn from local cache ✅");
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}dragandlearn.php'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"book_id": bookId}),
      );

      final data = json.decode(response.body);
      debugPrint("Drag & Learn API Response: $data");

      if (data['status'] == 'success') {
        if (levelFrom != null && levelFrom > savedLevel) {
          pref.setInt("DragAndLearnQuestLevel", levelFrom);
          savedLevel = levelFrom;
        }

        DragAndLearnLevelModel model = DragAndLearnLevelModel.fromJson(data);

        for (final Data topic in model.data ?? <Data>[]) {
          for (final Levels level in topic.levels ?? <Levels>[]) {
            for (final Questions q in level.questions ?? <Questions>[]) {
              final String? imageUrl = q.qusImage;

              if (imageUrl != null && imageUrl.isNotEmpty) {
                if (imageUrl.startsWith('http') ||
                    imageUrl.startsWith('https') ||
                    imageUrl.startsWith('www')) {
                  final String fullUrl = imageUrl.contains('picturoenglish.com')
                      ? imageUrl
                      : 'https://picturoenglish.com/admin/$imageUrl';

                  final String? localPath = await downloadAndSaveImage(fullUrl);
                  if (localPath != null) {
                    q.qusImage = localPath;
                    print('✅ Saved image locally: $localPath');
                  }
                } else {
                  print('ℹ️ Skipping non-URL image: $imageUrl');
                }
              }
            }
          }
        }
        
        await DragLearnLocalHelper.saveToLocal(model);
        debugPrint("Saved Drag & Learn to local cache ✅");

        emit(DragLearnLoaded(model, savedLevel));
      } else {
        emit(DragLearnFailed("API responded with failure ❌"));
      }
    } catch (e) {
      emit(DragLearnFailed("Error: $e"));
    }
  }

  Future<String?> downloadAndSaveImage(String url) async {
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
          'https://cdn.jsdelivr.net/gh/Mercurysoftech/PicturoEnglish@main/images_app/$url'));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        return path;
      } else {
        debugPrint("Image download failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
    }
    return null;
  }
}

class DragLearnLocalHelper {
  static const _cacheKey = 'drag_learn_data';

  static Future<void> saveToLocal(DragAndLearnLevelModel model) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode({
      'status': model.status,
      'data': model.data
          ?.map((topic) => {
                'topic_id': topic.topicId,
                'levels': topic.levels
                    ?.map((lvl) => {
                          'level': lvl.level,
                          'completed': lvl.completed,
                          'questions': lvl.questions
                              ?.map((q) => {
                                    'id': q.id,
                                    'question': q.question,
                                    'meaning': q.meaning,
                                    'example': q.example,
                                    'qus_image': q.qusImage,
                                  })
                              .toList(),
                        })
                    .toList(),
              })
          .toList(),
    });

    await prefs.setString(_cacheKey, jsonString);
  }

  static Future<DragAndLearnLevelModel?> getFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) return null;

    final jsonMap = jsonDecode(jsonString);
    return DragAndLearnLevelModel.fromJson(jsonMap);
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}

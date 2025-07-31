import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dragand_learn_model.dart';
import '../../services/api_service.dart';
part 'drag_and_learn_state.dart';


class DragLearnCubit extends Cubit<DragLearnState> {
  DragLearnCubit() : super(DragLearnLoading());

  Future<void> fetchDragLearnData({required int bookId,bool? isLoading,int? levelFrom}) async {
    (isLoading!=null&&isLoading)?null:emit(DragLearnLoading());
    SharedPreferences pref =await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    // try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}dragandlearn.php'),
         headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
      },
        body: jsonEncode({"book_id": bookId}),
      );

    final data = json.decode(response.body);
    log("sdcsklclskc ${{"book_id": bookId}} ${data}");

    if (data['status'] == 'success') {
      SharedPreferences pref = await SharedPreferences.getInstance();
      int savedLevel = pref.getInt("DragAndLearnQuestLevel") ?? 0;

      if (levelFrom != null && levelFrom > savedLevel) {
        pref.setInt("DragAndLearnQuestLevel", levelFrom);
        savedLevel = levelFrom;
      }

      DragAndLearnLevelModel dataj = DragAndLearnLevelModel.fromJson(data);
      emit(DragLearnLoaded(dataj, savedLevel));
    } else {
        emit(DragLearnFailed("API responded with failure"));
      }
    // } catch (e) {
    //   emit(DragLearnFailed("Error: $e"));
    // }
  }
}
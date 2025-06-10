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

  Future<void> fetchDragLearnData({required int bookId,bool? isLoading}) async {
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
      print("sdlkmclskdcm,sl;dcsdl;c,s;dlc, ${response.body}");
    final data = json.decode(response.body);

      if (data['status'] == 'success') {

        DragAndLearnLevelModel dataj=DragAndLearnLevelModel.fromJson(data);

        emit(DragLearnLoaded(dataj));
      } else {
        emit(DragLearnFailed("API responded with failure"));
      }
    // } catch (e) {
    //   emit(DragLearnFailed("Error: $e"));
    // }
  }
}

import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'quest_game_qtn_list_state.dart';

class GrammarQuestCubit extends Cubit<GrammarQuestState> {
  GrammarQuestCubit() : super(GrammarQuestLoading());

  Future<void> fetchGrammarQuestions({int? levelFrom}) async {
    emit(GrammarQuestLoading());
    final url = Uri.parse("http://picturoenglish.com/api/grammer_quest.php");

    // try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {

        final List data = json.decode(response.body);
        log("sdjclskmcsdkcms;ldc __ ${data}");


        final questions = data.map((e) => GrammarQuestion.fromJson(e)).toList();
        SharedPreferences pref=await SharedPreferences.getInstance();
        int? level=pref.getInt("QuestLevel");
        if(level!=null&&levelFrom!=null){
          level=levelFrom??0;
          pref.setInt("QuestLevel", level);
        }else{
          // level=levelFrom;
          // pref.setInt("QuestLevel", levelFrom??0);
        }
        emit(GrammarQuestLoaded(questions.cast<GrammarQuestion>(),level??0));
      } else {
        emit(GrammarQuestFailed('Server error: ${response.statusCode}'));
      }
    // } catch (e) {
    //   emit(GrammarQuestFailed('Error: $e'));
    // }
  }
}

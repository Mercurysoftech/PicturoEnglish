// quest_game_qtn_list_cubit.dart
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:picturo_app/responses/grammar_quest_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'quest_game_qtn_list_state.dart';

class GrammarQuestCubit extends Cubit<GrammarQuestState> {
  GrammarQuestCubit() : super(GrammarQuestLoading());

  Future<void> fetchGrammarQuestions({int? levelFrom}) async {
    emit(GrammarQuestLoading());
    final url = Uri.parse("http://picturoenglish.com/api/grammer_quest.php");

    try {
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
        final jsonData = json.decode(response.body);
        
        // Parse the response using GrammarResponse model
        final grammarResponse = GrammarResponse.fromJson(jsonData);
        
        // Check if should show subscription dialog
        final bool shouldShowSubscriptionDialog = 
            grammarResponse.isFreeHitUser && !grammarResponse.isSubscribePlan;

        log("Is Free User: ${grammarResponse.isFreeHitUser}");
        log("Is Subscribed: ${grammarResponse.isSubscribePlan}");
        log("Progress: ${grammarResponse.progressPercentage}%");
        log("Max Allowed: ${grammarResponse.maxAllowedPercentage}%");

        emit(GrammarQuestLoaded(
          grammarResponse.levels,
          shouldShowSubscriptionDialog: shouldShowSubscriptionDialog,
          isFreeHitUser: grammarResponse.isFreeHitUser,
          isSubscribePlan: grammarResponse.isSubscribePlan,
          progressPercentage: grammarResponse.progressPercentage,
          maxAllowedPercentage: grammarResponse.maxAllowedPercentage,
        ));
      } else {
        emit(GrammarQuestFailed('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      log('Error fetching grammar questions: $e');
      emit(GrammarQuestFailed('Error: $e'));
    }
  }
}
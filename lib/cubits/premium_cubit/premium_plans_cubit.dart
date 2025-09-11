import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:picturo_app/responses/remaining_usage_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/current_premieum_model.dart';
import '../../models/premium_plan_model.dart';
part 'premium_plans_state.dart';


class PlanCubit extends Cubit<PlanState> {
  PlanCubit() : super(PlanInitial());

  Future<void> fetchPlansAndCurrent() async {
    emit(PlanLoading());
    // try {
      /// Fetch all plans
      final plansResponse = await http.get(Uri.parse("https://picturoenglish.com/api/package-plan.php"));
      List<PlanModel> plans = [];

      if (plansResponse.statusCode == 200) {
        final data = json.decode(plansResponse.body);

        if (data is Map && data["data"] is List) {
          plans = (data["data"] as List)
              .map((e) => PlanModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }

      /// Fetch current plan
      final currentPlan = await _fetchCurrentPlan();


      emit(PlanLoaded(plans: plans, currentPlan: currentPlan));
    // } catch (e) {
    //   emit(PlanError("Error fetching data: $e"));
    // }
  }

  Future<PremiumResponse?> _fetchCurrentPlan() async {
    // try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final response = await http.get(
        Uri.parse("https://picturoenglish.com/api/premium.php?mode=all"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      log("ldkscmlksdcsd ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

          return PremiumResponse.fromJson(jsonData);
      }
    // } catch (e) {
    //   print("Error fetching current plan: $e");
    // }
    return null;
  }

  Future<RemainingUsageResponse?> fetchRemainingBotCalls() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        log("No authentication token found");
        return null;
      }

      final response = await http.get(
        Uri.parse("https://picturoenglish.com/api/remaining-bot-call-view.php"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      log("Remaining Bot Calls API Response: ${response.body}");
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RemainingUsageResponse.fromJson(jsonData);
      } else {
        log("Failed to fetch remaining bot calls. Status code: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching remaining bot calls: $e");
    }
    return null;
  }
}



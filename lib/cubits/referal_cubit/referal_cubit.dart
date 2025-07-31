import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/referal_model.dart';
part 'referal_state.dart';



class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit() : super(ReferralInitial());

  Future<void> fetchReferralEarnings() async {
    emit(ReferralLoading());
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final response = await http.get(
        Uri.parse("http://picturoenglish.com/api/refferal_earnings_counts.php"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final earnings = ReferralEarnings.fromJson(Map<String, dynamic>.from(jsonData));
        emit(ReferralLoaded(earnings));
      } else {
        emit(ReferralError("Failed to fetch data"));
      }
    } catch (e) {
      emit(ReferralError(e.toString()));
    }
  }
}

import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

part 'faq_details_state.dart';


class FAQCubit extends Cubit<FAQState> {
  FAQCubit() : super(FAQInitial());

  Future<void> fetchFAQs() async {

    emit(FAQLoading());
    try {
      SharedPreferences pref =await SharedPreferences.getInstance();
      String? token = pref.getString("auth_token");
      final response = await http.get(Uri.parse('http://picturoenglish.com/api/faq.php'),
        headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == true && body['data'] != null) {
          List<FAQ> faqs = (body['data'] as List)
              .map((item) => FAQ.fromJson(item))
              .toList();
          emit(FAQLoaded(faqs));
        } else {
          emit(const FAQError("No data available."));
        }
      } else {
        emit(FAQError("Failed to load FAQs. Code: ${response.statusCode}"));
      }
    } catch (e) {
      emit(FAQError("Error: $e"));
    }
  }
}

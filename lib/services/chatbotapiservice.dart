import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:picturo_app/responses/chatbot_plainfo_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBotApiService {
  final Dio _dio;
  static const int _timeoutSeconds = 30;

  ChatBotApiService._(this._dio);

  static Future<ChatBotApiService> create() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    final dio = Dio(
      BaseOptions(
        baseUrl: "http://37.27.187.66:2030/",
        connectTimeout: Duration(seconds: _timeoutSeconds),
        receiveTimeout: Duration(seconds: _timeoutSeconds),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        // Allow all status codes without throwing
        validateStatus: (status) => true,
      ),
    );

    // Add interceptors for better logging and error handling
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Sending request to ${options.uri}');
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        print('DioError occurred: $error');
        return handler.next(error);
      },
    ));

    return ChatBotApiService._(dio);
  }

  Future<PlanInfoResponse> getChatBotPlanInfo({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        throw Exception("Authorization token is missing. Please log in.");
      }

      final response = await _dio.get(
        "http://picturoenglish.com/api/get_plan_info.php",
        data: {"user_id": userId.toString()},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Plan Info API Response: ${response.data}");

      if (response.statusCode == 200) {
        return PlanInfoResponse.fromJson(response.data);
      } else {
        throw Exception(
            response.data["message"] ?? "Failed to fetch plan info");
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data["message"] ?? "Network error: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  Future<AiMultiLanguageResponseModel> getChatbotResponse({
    required String message,
    required String language,
    required String scenario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');

    log("Request data: ${{"message": "$message", "user_id": currentUserId}}");

    try {
      final response = await _dio
          .post(
            'chat',
            data: jsonEncode({"message": "$message", "user_id": currentUserId}),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      print("Response: ${response.data}");

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid status code: ${response.statusCode}',
        );
      }

      final dataMap = response.data;

      // Handle error response (even with 200 status)
      if (dataMap['error'] != null && dataMap['error'].toString().isNotEmpty) {
        return AiMultiLanguageResponseModel.fromJson(dataMap);
      }

      // Handle successful response
      return AiMultiLanguageResponseModel.fromJson(dataMap);
    } on DioException catch (e) {
      print('DioError in getChatbotResponse: $e');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response headers: ${e.response?.headers}');

        // Handle specific error codes
        if (e.response?.statusCode == 402) {
          throw Exception('Payment required. Please check your subscription.');
        } else if (e.response?.statusCode == 403) {
          throw Exception('Access forbidden. Invalid token or permissions.');
        }
      }
      rethrow;
    } on TimeoutException catch (e) {
      print('Timeout in getChatbotResponse: $e');
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      print('Unexpected error in getChatbotResponse: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }
}

class AiMultiLanguageResponseModel {
  final String? error;
  final String input;
  final String response;
  final String modelUsed;
  final PlanInfo? planInfo;
  final TokenInfo? tokens;

  AiMultiLanguageResponseModel({
    this.error,
    required this.input,
    required this.response,
    required this.modelUsed,
    this.planInfo,
    this.tokens,
  });

  factory AiMultiLanguageResponseModel.fromJson(Map<String, dynamic> json) {
    return AiMultiLanguageResponseModel(
      error: json['error'],
      input: json['input'] ?? "",
      response: json['response'] ??
          json['message'] ??
          "Sorry I can't Understand Enter Valid Message Please",
      modelUsed: json['model_used'] ?? "",
      planInfo: json['plan_info'] != null
          ? PlanInfo.fromJson(json['plan_info'])
          : null,
      tokens:
          json['tokens'] != null ? TokenInfo.fromJson(json['tokens']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'input': input,
      'response': response,
      'model_used': modelUsed,
      'plan_info': planInfo?.toJson(),
      'tokens': tokens?.toJson(),
    };
  }
}

class PlanInfo {
  final double dailyLimit;
  final int estimatedConversationsLeft;
  final bool planActive;
  final String planType;
  final double remainingBudget;
  final double usedToday;

  PlanInfo({
    required this.dailyLimit,
    required this.estimatedConversationsLeft,
    required this.planActive,
    required this.planType,
    required this.remainingBudget,
    required this.usedToday,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      dailyLimit: _safeParseDouble(json['daily_limit']),
      estimatedConversationsLeft:
          _safeParseInt(json['estimated_conversations_left']),
      planActive: _safeParseBool(json['plan_active']),
      planType: json['plan_type']?.toString() ?? "",
      remainingBudget: _safeParseDouble(json['remaining_budget']),
      usedToday: _safeParseDouble(json['used_today']),
    );
  }

  static double _safeParseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _safeParseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit': dailyLimit,
      'estimated_conversations_left': estimatedConversationsLeft,
      'plan_active': planActive,
      'plan_type': planType,
      'remaining_budget': remainingBudget,
      'used_today': usedToday,
    };
  }
}

class TokenInfo {
  final double costRupees;
  final int input;
  final int output;
  final int total;
  final double dailyTotalCost;
  final String dailyTotalInput;
  final String dailyTotalOutput;
  final String dailyTotalTokens;

  TokenInfo({
    required this.costRupees,
    required this.input,
    required this.output,
    required this.total,
    required this.dailyTotalCost,
    required this.dailyTotalInput,
    required this.dailyTotalOutput,
    required this.dailyTotalTokens,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      costRupees: _safeParseDouble(json['cost_rupees']),
      input: _safeParseInt(json['input']),
      output: _safeParseInt(json['output']),
      total: _safeParseInt(json['total']),
      dailyTotalCost: _safeParseDouble(json['daily_total_cost']),
      dailyTotalInput: json['daily_total_input']?.toString() ?? "0",
      dailyTotalOutput: json['daily_total_output']?.toString() ?? "0",
      dailyTotalTokens: json['daily_total_tokens']?.toString() ?? "0",
    );
  }

  static double _safeParseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'cost_rupees': costRupees,
      'input': input,
      'output': output,
      'total': total,
      'daily_total_cost': dailyTotalCost,
      'daily_total_input': dailyTotalInput,
      'daily_total_output': dailyTotalOutput,
      'daily_total_tokens': dailyTotalTokens,
    };
  }
}
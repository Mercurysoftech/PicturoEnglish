import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';


class ChatBotApiService {
  final Dio _dio;
  static const int _timeoutSeconds=30;

   ChatBotApiService._(this._dio);

  static Future<ChatBotApiService> create() async {
    SharedPreferences pref =await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    final dio = Dio(
      BaseOptions(
        baseUrl: "http://37.27.187.66:2030/",
        connectTimeout: Duration(seconds: _timeoutSeconds),
        receiveTimeout: Duration(seconds: _timeoutSeconds),
        headers:  {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"},
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


 Future<AiMultiLanguageResponseModel> getChatbotResponse({
    required String message,
    required String language,
    required String scenario,
  }) async {
    // try {
   final prefs = await SharedPreferences.getInstance();
   final currentUserId = prefs.getString('user_id');
   log(";sdklclk;sdmclskcmsdc ${{
     "message": "$message",
     "user_id":currentUserId
   }}");
      final response = await _dio.post(
        'chat',
        data: jsonEncode({
          "message": "$message",
          "user_id":currentUserId
          // "scenario": "$scenario"
        }),
      ).timeout(const Duration(seconds: _timeoutSeconds));

      print("Response: ${response.data}");

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid status code: ${response.statusCode}',
        );
      } else {
        final dataMap = response.data;

        // Handle error inside 200 response
        if (dataMap['error'] != null && dataMap['error'].toString().isNotEmpty) {
          throw Exception(dataMap['error']);
        }

        return AiMultiLanguageResponseModel.fromJson(dataMap);
      }




      // Validate response structure
      // print("sdlkcms;lkc;klsdc hh ${response.data['message'] == null ||
      //     response.data['status'] == null}");
      // if (response.data['message'] == null ||
      //     response.data['status'] == null) {
      //   throw DioException(
      //     requestOptions: response.requestOptions,
      //     error: 'Invalid response format',
      //   );
      // }
     print("sdljcnslcmslkcmsdckl ${{
       'audio_base64': response.data['audio_base64'],
       'reply': response.data['message'],
       'status': response.data['status'],
     }}");

    // } on DioException catch (e) {
    //   print('DioError in getChatbotResponse: ${e}');
    //   if (e.response != null) {
    //     print('Response data: ${e.response?.data}');
    //     print('Response headers: ${e.response?.headers}');
    //   }
    //   return {
    //     'error': _handleDioError(e),
    //     'status': 'error',
    //   };
    // } on TimeoutException catch (e) {
    //   print('Timeout in getChatbotResponse: $e');
    //   return {
    //     'error': 'Request timed out. Please try again.',
    //     'status': 'timeout',
    //   };
    // } catch (e) {
    //   print('Unexpected error in getChatbotResponse: $e');
    //   return {
    //     'error': 'An unexpected error occurred. Please try again.',
    //     'status': 'error',
    //   };
    // }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please check your internet connection.';
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404) {
          return 'Endpoint not found (404)';
        } else if (error.response?.statusCode == 500) {
          return 'Server error (500)';
        } else {
          return 'Server responded with error: ${error.response?.statusCode}';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'No internet connection';
        }
        return 'Unknown error occurred';
      default:
        return 'Network error occurred';
    }
  }

}

class AiMultiLanguageResponseModel {
  final String input;
  final String response;
  final Map<String, String> translations;

  AiMultiLanguageResponseModel({
    required this.input,
    required this.response,
    required this.translations,
  });

  factory AiMultiLanguageResponseModel.fromJson(Map<String, dynamic> json) {
    return AiMultiLanguageResponseModel(
      input: json['input'],
      response: json['response'],
      translations: Map<String, String>.from(json['translations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'response': response,
      'translations': translations,
    };
  }
}

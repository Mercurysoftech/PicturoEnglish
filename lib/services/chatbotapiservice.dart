import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ChatBotApiService {
  final Dio _dio;
  static const int _timeoutSeconds=30;

   ChatBotApiService._(this._dio);

  static Future<ChatBotApiService> create() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://147.79.67.167:2027/',
        connectTimeout: Duration(seconds: _timeoutSeconds),
        receiveTimeout: Duration(seconds: _timeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
        },
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


 Future<Map<String, dynamic>> getChatbotResponse({
    required String message,
    required String language,
    required String scenario,
  }) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'message': message,
          'language': language,
          'scenario': scenario,
        },
      ).timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid status code: ${response.statusCode}',
        );
      }

      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Empty response from server',
        );
      }

      // Validate response structure
      if (response.data['reply'] == null || 
          response.data['status'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Invalid response format',
        );
      }

      return {
        'audio_base64': response.data['audio_base64'],
        'reply': response.data['reply'],
        'status': response.data['status'],
      };
    } on DioException catch (e) {
      print('DioError in getChatbotResponse: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response headers: ${e.response?.headers}');
      }
      return {
        'error': _handleDioError(e),
        'status': 'error',
      };
    } on TimeoutException catch (e) {
      print('Timeout in getChatbotResponse: $e');
      return {
        'error': 'Request timed out. Please try again.',
        'status': 'timeout',
      };
    } catch (e) {
      print('Unexpected error in getChatbotResponse: $e');
      return {
        'error': 'An unexpected error occurred. Please try again.',
        'status': 'error',
      };
    }
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
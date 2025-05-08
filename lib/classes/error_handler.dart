import 'dart:async';

import 'package:dio/dio.dart';

class ErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is TimeoutException) {
      return "The request took too long. Please check your internet connection and try again.";
    } else {
      return "Something went wrong. Please try again later.";
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timed out. Please check your internet connection.";
      
      case DioExceptionType.badCertificate:
        return "Security error occurred. Please try again later.";
      
      case DioExceptionType.badResponse:
        return _handleBadResponse(error);
      
      case DioExceptionType.cancel:
        return "Request was cancelled";
      
      case DioExceptionType.connectionError:
        return "No internet connection. Please check your network settings.";
      
      case DioExceptionType.unknown:
        if (error.message?.contains("SocketException") ?? false) {
          return "No internet connection available.";
        }
        return "An unexpected error occurred. Please try again.";
    }
  }

  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    
    if (statusCode == null) {
      return "Server returned an invalid response.";
    }

    switch (statusCode) {
      case 400:
        return "Invalid request. Please try again with different inputs.";
      case 401:
      case 403:
        return "Authentication failed. Please login again.";
      case 404:
        return "The requested resource was not found.";
      case 500:
      case 502:
      case 503:
        return "Our servers are currently busy. Please try again later.";
      default:
        return "Server error occurred (Code: $statusCode)";
    }
  }
}
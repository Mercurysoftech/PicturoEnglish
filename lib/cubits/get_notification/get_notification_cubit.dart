import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notification_model.dart';

part 'get_notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());
  
  // Cache the notifications to prevent unnecessary reloading
  List<NotificationModel> _cachedNotifications = [];
  bool _isLoading = false;

  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    // If already loading, don't start another load
    if (_isLoading) return;
    
    // If we have cached data and not forcing refresh, return cached data
    if (!forceRefresh && _cachedNotifications.isNotEmpty) {
      emit(NotificationLoaded(_cachedNotifications));
      return;
    }
    
    _isLoading = true;
    emit(NotificationLoading());
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    try {
      final response = await http.get(
        Uri.parse('https://picturoenglish.com/api/get_notifications.php'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] is List) {
          final allNotifications = (data['data'] as List)
              .map((e) => NotificationModel.fromJson(e))
              .toList()
              .reversed // Show newest first
              .toList();

          // Cache the notifications
          _cachedNotifications = allNotifications;

          if (allNotifications.isNotEmpty) {
            emit(NotificationLoaded(allNotifications));
          } else {
            emit(NotificationLoaded([]));
          }
        } else {
          // Return empty list on error but don't show error to user
          emit(NotificationLoaded([]));
        }
      } else {
        // Return cached data if available, otherwise empty list
        if (_cachedNotifications.isNotEmpty) {
          emit(NotificationLoaded(_cachedNotifications));
        } else {
          emit(NotificationLoaded([]));
        }
      }
    } catch (e) {
      // Return cached data if available, otherwise empty list
      if (_cachedNotifications.isNotEmpty) {
        emit(NotificationLoaded(_cachedNotifications));
      } else {
        emit(NotificationLoaded([]));
      }
    } finally {
      _isLoading = false;
    }
  }
  
  // Clear cache (call on logout)
  void clearCache() {
    _cachedNotifications.clear();
  }
}
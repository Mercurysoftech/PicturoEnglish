import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notification_model.dart';

part 'get_notification_state.dart';
// cubits/notification_cubit/notification_cubit.dart

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());

  Future<void> fetchNotifications() async {
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
              .toList();

          // Filter today's notifications
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final todayNotifications = allNotifications.where((notification) {
            final createdAt = DateTime.tryParse(notification.createdAt ?? '');
            if (createdAt == null) return false;
            final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
            return createdDate == today;
          }).toList();

          if (todayNotifications.isNotEmpty) {
            emit(NotificationLoaded(todayNotifications));
          } else {
            emit(const NotificationError("No notifications for today."));
          }
        } else {
          emit(const NotificationError("No notifications found."));
        }
      } else {
        emit(NotificationError("Failed with status: ${response.statusCode}"));
      }
    } catch (e) {
      emit(NotificationError("Error: $e"));
    }
  }

}

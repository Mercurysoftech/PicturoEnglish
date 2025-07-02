// models/notification_model.dart
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String body;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      createdAt: json['created_at'],
    );
  }

  @override
  List<Object?> get props => [id, title, body, createdAt];
}

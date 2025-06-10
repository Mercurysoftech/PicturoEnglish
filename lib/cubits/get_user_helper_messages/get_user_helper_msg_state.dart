part of 'get_user_helper_msg_cubit.dart';


abstract class UserSupportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserSupportInitial extends UserSupportState {}

class UserSupportLoading extends UserSupportState {}

class UserSupportLoaded extends UserSupportState {
  final List<Map<String, String>>  supports;

  UserSupportLoaded(this.supports);

  @override
  List<Object?> get props => [supports];
}

class UserSupportError extends UserSupportState {
  final String error;

  UserSupportError(this.error);

  @override
  List<Object?> get props => [error];
}
class SupportMessage {
  final String type;
  final String message;
  final String createdAt;

  SupportMessage({
    required this.type,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      type: json['type'],
      message: json['message'],
      createdAt: json['created_at'],
    );
  }
}

// models/user_support.dart
class UserSupport {
  final int userId;
  final List<SupportMessage> messages;

  UserSupport({
    required this.userId,
    required this.messages,
  });

  factory UserSupport.fromJson(Map<String, dynamic> json) {
    return UserSupport(
      userId: json['user_id'],
      messages: List<SupportMessage>.from(
        json['messages'].map((msg) => SupportMessage.fromJson(msg)),
      ),
    );
  }
}
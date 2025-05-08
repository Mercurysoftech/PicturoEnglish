class UsersResponse {
  final bool status;
  final List<User> data;

  UsersResponse({required this.status, required this.data});

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    return UsersResponse(
      status: json['status'],
      data: (json['data'] as List).map((user) => User.fromJson(user)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((user) => user.toJson()).toList(),
    };
  }
}

class User {
  final int id;
  final String username;
  int avatar_id;
  int chat_request_status;
  String chat_status;

  User({required this.id, required this.username, required this.avatar_id,required this.chat_request_status,required this.chat_status});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      avatar_id: json['avatar_id'],
      chat_request_status:json['chat_request_status'],
      chat_status:json['chat_status']

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_id': avatar_id,
      'chat_request_status':chat_request_status,
      'chat_status':chat_status
    };
  }
}
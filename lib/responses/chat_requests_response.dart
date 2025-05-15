class RequestsResponse {
  final bool status;
  // ignore: non_constant_identifier_names
  final List<Requests> received_requests;

  // ignore: non_constant_identifier_names
  RequestsResponse({required this.status, required this.received_requests});

  factory RequestsResponse.fromJson(Map<String, dynamic> json) {
    return RequestsResponse(
      status: json['status'],
      received_requests: (json['received_requests'] as List)
          .map((user) => Requests.fromJson(user))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'received_requests': received_requests.map((user) => user.toJson()).toList(),
    };
  }
}

class Requests {
  final int id;
  final int sender_id;
  final String status;
  final String created_at;
  final String username;
  final int age;
  final String gender;
  final String speaking_level;
  final int avatar_id;

  Requests({
    required this.id,
    required this.sender_id,
    required this.status,
    required this.created_at,
    required this.username,
    required this.age,
    required this.gender,
    required this.speaking_level,
    required this.avatar_id,
  });

  factory Requests.fromJson(Map<String, dynamic> json) {
    return Requests(
      id: json['id'],
      sender_id: json['sender_id'],
      status: json['status'], 
      created_at: json['created_at'],
      username: json['username'],
      age: json['age'],
      gender: json['gender'],
      speaking_level: json['speaking_level'],
      avatar_id: json['avatar_id']??0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': sender_id,
      'status': status,
      'created_at': created_at,
      'username': username,
      'age': age,
      'gender': gender,
      'speaking_level': speaking_level,
      'avatar_id': avatar_id,
    };
  }
}

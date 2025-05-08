class FriendsResponse {
  final bool status;
  final List<Friends> data;

  FriendsResponse({required this.status, required this.data});

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      status: json['status'],
      data: (json['friends'] as List).map((user) => Friends.fromJson(user)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'friends': data.map((user) => user.toJson()).toList(),
    };
  }
}

class Friends {
  final int friend_id;
  final String friend_name;
  final int friend_profile_pic;
  final String status;
  final String accepted_at;

  Friends({required this.friend_id, required this.friend_name, required this.friend_profile_pic,required this.status,required this.accepted_at});

  factory Friends.fromJson(Map<String, dynamic> json) {
    return Friends(
      friend_id: json['friend_id'],
      friend_name: json['friend_name'],
      friend_profile_pic: json['friend_profile_pic'],
      status:json['status'],
      accepted_at:json['accepted_at']

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': friend_id,
      'friend_name': friend_name,
      'friend_profile_pic': friend_profile_pic,
      'status':status,
      'accepted_at':accepted_at
    };
  }
}
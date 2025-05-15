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
  int? friendId;
  String? friendName;
  int? friendProfilePic;
  String? status;
  String? acceptedAt;
  String? lastMessage;
  String? lastMessageTime;
  String? lastMessageDirection;
  int? unreadCount;

  Friends(
      {this.friendId,
        this.friendName,
        this.friendProfilePic,
        this.status,
        this.acceptedAt,
        this.lastMessage,
        this.lastMessageTime,
        this.lastMessageDirection,
        this.unreadCount});

  Friends.fromJson(Map<String, dynamic> json) {
    friendId = json['friend_id'];
    friendName = json['friend_name'];
    friendProfilePic = json['friend_profile_pic'];
    status = json['status'];
    acceptedAt = json['accepted_at'];
    lastMessage = json['last_message'];
    lastMessageTime = json['last_message_time'];
    lastMessageDirection = json['last_message_direction'];
    unreadCount = json['unread_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['friend_id'] = this.friendId;
    data['friend_name'] = this.friendName;
    data['friend_profile_pic'] = this.friendProfilePic;
    data['status'] = this.status;
    data['accepted_at'] = this.acceptedAt;
    data['last_message'] = this.lastMessage;
    data['last_message_time'] = this.lastMessageTime;
    data['last_message_direction'] = this.lastMessageDirection;
    data['unread_count'] = this.unreadCount;
    return data;
  }
}


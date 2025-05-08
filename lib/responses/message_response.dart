class MessagesResponse {
  final bool status;
  final List<Message> messages;

  MessagesResponse({required this.status, required this.messages});

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      status: json['status'],
      messages: (json['messages'] as List).map((msg) => Message.fromJson(msg)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String formattedTime;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.formattedTime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      formattedTime: json['formatted_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'formatted_time': formattedTime,
    };
  }
}
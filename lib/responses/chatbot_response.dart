class ChatResponse {
  final String reply;
  final String? error;  // optional field
  final DateTime? timestamp;  // optional field

  ChatResponse({
    required this.reply,
    this.error,
    this.timestamp,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'],
      error: json['error'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'error': error,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}
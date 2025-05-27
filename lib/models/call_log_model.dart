class CallLog {
  final int id;
  final int callerId;
  final int receiverId;
  final String callType;
  final String userName;
  final String status;
  final int duration;
  final String createdAt;

  CallLog({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.userName,
    required this.status,
    required this.duration,
    required this.createdAt,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'],
      callerId: json['caller_id'],
      receiverId: json['receiver_id'],
      callType: json['call_type'],
      userName: json['userName'],
      status: json['status'],
      duration: json['duration'],
      createdAt: json['created_at'],
    );
  }
}

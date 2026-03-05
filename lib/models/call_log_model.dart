class CallLog {
  final int id;
  final int callerId;
  final int receiverId;
  final String callType;
  final String callerUserName;
  final String receiverUserName;
  final String status;
  final int duration;
  final String createdAt;

  CallLog({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.callerUserName,
    required this.receiverUserName,
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
      status: json['status'],
      duration: json['duration'],
      createdAt: json['created_at'],
      callerUserName: json['caller_username']??"",
      receiverUserName: json['receiver_username']??"",
    );
  }
}

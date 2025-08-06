// class PremiumResponse {
//   final String status;
//   final List<Membership> membership;
//
//   PremiumResponse({required this.status, required this.membership});
//
//   factory PremiumResponse.fromJson(Map<String, dynamic> json) {
//     return PremiumResponse(
//       status: json['status'],
//       membership: (json['membership'] as List)
//           .map((item) => Membership.fromJson(item))
//           .toList(),
//     );
//   }
// }
//
// class Membership {
//   final String membership;
//   final String planVoiceCall;
//   final String planMessage;
//   final String planGames;
//   final String planChatbot;
//   final String planStartTime;
//   final String planEndTime;
//
//   Membership({
//     required this.membership,
//     required this.planVoiceCall,
//     required this.planMessage,
//     required this.planGames,
//     required this.planChatbot,
//     required this.planStartTime,
//     required this.planEndTime,
//   });
//
//   factory Membership.fromJson(Map<String, dynamic> json) {
//     return Membership(
//       membership: json['membership'],
//       planVoiceCall: json['plan_voicecall'],
//       planMessage: json['plan_message'],
//       planGames: json['plan_games'],
//       planChatbot: json['plan_chatbot'],
//       planStartTime: json['plan_start_time'],
//       planEndTime: json['plan_end_time'],
//     );
//   }
// }
class PremiumResponse {
  bool? status;
  String? message;
  List<Data>? data;

  PremiumResponse({this.status, this.message, this.data});

  PremiumResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  int? userId;
  int? planId;
  String? startDate;
  String? endDate;
  String? status;
  int? remainingCallMinutes;
  int? remainingChatbotPrompts;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
        this.userId,
        this.planId,
        this.startDate,
        this.endDate,
        this.status,
        this.remainingCallMinutes,
        this.remainingChatbotPrompts,
        this.createdAt,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    userId = json['user_id'] ?? 0;
    planId = json['plan_id'] ?? 0;
    startDate = json['start_date']?.toString() ?? '';
    endDate = json['end_date']?.toString() ?? '';
    status = json['status']?.toString() ?? '';
    remainingCallMinutes = json['remaining_call_minutes'] ?? 0;
    remainingChatbotPrompts = json['remaining_chatbot_prompts'] ?? 0;
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['plan_id'] = this.planId;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['status'] = this.status;
    data['remaining_call_minutes'] = this.remainingCallMinutes;
    data['remaining_chatbot_prompts'] = this.remainingChatbotPrompts;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

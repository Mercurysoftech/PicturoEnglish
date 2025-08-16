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
  String? subscriptionCreatedAt;
  String? subscriptionUpdatedAt;
  String? planName;
  String? description;
  String? type;
  int? validityDays;
  int? callLimitPerDay;
  String? chatbotPromptLimit;
  int? isUnlimitedCall;
  int? isUnlimitedChat;
  String? price;
  String? planCreatedAt;
  String? planUpdatedAt;

  Data(
      {this.id,
        this.userId,
        this.planId,
        this.startDate,
        this.endDate,
        this.status,
        this.remainingCallMinutes,
        this.remainingChatbotPrompts,
        this.subscriptionCreatedAt,
        this.subscriptionUpdatedAt,
        this.planName,
        this.description,
        this.type,
        this.validityDays,
        this.callLimitPerDay,
        this.chatbotPromptLimit,
        this.isUnlimitedCall,
        this.isUnlimitedChat,
        this.price,
        this.planCreatedAt,
        this.planUpdatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    planId = json['plan_id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    status = json['status'];
    remainingCallMinutes = json['remaining_call_minutes'];
    remainingChatbotPrompts = json['remaining_chatbot_prompts'];
    subscriptionCreatedAt = json['subscription_created_at'];
    subscriptionUpdatedAt = json['subscription_updated_at'];
    planName = json['plan_name'];
    description = json['description'].toString();
    type = json['type'];
    validityDays = json['validity_days'];
    callLimitPerDay = json['call_limit_per_day'];
    chatbotPromptLimit = json['chatbot_prompt_limit'].toString();
    isUnlimitedCall = json['is_unlimited_call'];
    isUnlimitedChat = json['is_unlimited_chat'];
    price = json['price'];
    planCreatedAt = json['plan_created_at'];
    planUpdatedAt = json['plan_updated_at'];
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
    data['subscription_created_at'] = this.subscriptionCreatedAt;
    data['subscription_updated_at'] = this.subscriptionUpdatedAt;
    data['plan_name'] = this.planName;
    data['description'] = this.description;
    data['type'] = this.type;
    data['validity_days'] = this.validityDays;
    data['call_limit_per_day'] = this.callLimitPerDay;
    data['chatbot_prompt_limit'] = this.chatbotPromptLimit;
    data['is_unlimited_call'] = this.isUnlimitedCall;
    data['is_unlimited_chat'] = this.isUnlimitedChat;
    data['price'] = this.price;
    data['plan_created_at'] = this.planCreatedAt;
    data['plan_updated_at'] = this.planUpdatedAt;
    return data;
  }
}


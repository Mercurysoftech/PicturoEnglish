class PremiumResponse {
  final String status;
  final List<Membership> membership;

  PremiumResponse({required this.status, required this.membership});

  factory PremiumResponse.fromJson(Map<String, dynamic> json) {
    return PremiumResponse(
      status: json['status'],
      membership: (json['membership'] as List)
          .map((item) => Membership.fromJson(item))
          .toList(),
    );
  }
}

class Membership {
  final String membership;
  final String planVoiceCall;
  final String planMessage;
  final String planGames;
  final String planChatbot;
  final String planStartTime;
  final String planEndTime;

  Membership({
    required this.membership,
    required this.planVoiceCall,
    required this.planMessage,
    required this.planGames,
    required this.planChatbot,
    required this.planStartTime,
    required this.planEndTime,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      membership: json['membership'],
      planVoiceCall: json['plan_voicecall'],
      planMessage: json['plan_message'],
      planGames: json['plan_games'],
      planChatbot: json['plan_chatbot'],
      planStartTime: json['plan_start_time'],
      planEndTime: json['plan_end_time'],
    );
  }
}

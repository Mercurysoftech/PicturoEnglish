class PlanModel {
  final String id;
  final String name;
  final String voiceCall;
  final String message;
  final String chatBot;
  final String games;
  final String validatePlan;
  final String price;

  PlanModel({
    required this.id,
    required this.name,
    required this.voiceCall,
    required this.message,
    required this.chatBot,
    required this.games,
    required this.validatePlan,
    required this.price,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json["id"]?.toString() ?? "",
      name: json["plan_name"] ?? "",
      voiceCall: json["voice_call"] ?? "",
      message: json["message"] ?? "",
      chatBot: json["chat_bot"] ?? "",
      games: json["games"] ?? "",
      validatePlan: json["validate_plan"] ?? "",
      price: json["price"] ?? "",
    );
  }

  /// Combine feature strings into a list for UI
  List<String> get features {
    final list = <String>[];
    if (voiceCall != "0" && voiceCall.isNotEmpty) list.add("Voice Call: $voiceCall");
    if (message != "0" && message.isNotEmpty) list.add("Messaging: $message");
    if (chatBot != "0" && chatBot.isNotEmpty) list.add("Chatbot: $chatBot");
    if (games != "0" && games.isNotEmpty) list.add("Games: $games");
    return list;
  }
}


// class PremiumResponse {
//   final List<Membership> membership;
//
//   PremiumResponse({required this.membership});
//
//   factory PremiumResponse.fromJson(Map<String, dynamic> json) {
//     return PremiumResponse(
//       membership: (json["membership"] as List)
//           .map((data) => Membership.fromJson(data))
//           .toList(),
//     );
//   }
// }
//
// class Membership {
//   final String membership;
//   final String planVoiceCall;
//   final String planStartTime;
//   final String planEndTime;
//
//   Membership({
//     required this.membership,
//     required this.planVoiceCall,
//     required this.planStartTime,
//     required this.planEndTime,
//   });
//
//   factory Membership.fromJson(Map<String, dynamic> json) {
//     return Membership(
//       membership: json["membership"] ?? "",
//       planVoiceCall: json["plan_voice_call"] ?? "",
//       planStartTime: json["plan_start_time"] ?? "",
//       planEndTime: json["plan_end_time"] ?? "",
//     );
//   }
// }

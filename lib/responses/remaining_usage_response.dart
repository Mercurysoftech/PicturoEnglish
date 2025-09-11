class RemainingUsageResponse {
  final bool status;
  final int userId;
  final MergedUsage? mergedUsage;

  RemainingUsageResponse({
    required this.status,
    required this.userId,
    this.mergedUsage,
  });

  factory RemainingUsageResponse.fromJson(Map<String, dynamic> json) {
    return RemainingUsageResponse(
      status: json['status'] as bool? ?? false,
      userId: json['user_id'] as int? ?? 0,
      mergedUsage: json['merged_usage'] != null ? MergedUsage.fromJson(json['merged_usage']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'user_id': userId,
      'merged_usage': mergedUsage?.toJson(),
    };
  }
}

class MergedUsage {
  final bool isUnlimitedCall;
  final bool isUnlimitedChat;
  final MonthlyUsage? monthly;
  final DailyUsage? daily;

  MergedUsage({
    required this.isUnlimitedCall,
    required this.isUnlimitedChat,
    this.monthly,
    this.daily,
  });

  factory MergedUsage.fromJson(Map<String, dynamic> json) {
    return MergedUsage(
      isUnlimitedCall: json['is_unlimited_call'] as bool? ?? false,
      isUnlimitedChat: json['is_unlimited_chat'] as bool? ?? false,
      monthly: json['monthly'] != null ? MonthlyUsage.fromJson(json['monthly']) : null,
      daily: json['daily'] != null ? DailyUsage.fromJson(json['daily']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_unlimited_call': isUnlimitedCall,
      'is_unlimited_chat': isUnlimitedChat,
      'monthly': monthly?.toJson(),
      'daily': daily?.toJson(),
    };
  }
}

class MonthlyUsage {
  final int usedCallMinutes;
  final dynamic balanceCallMinutes; // Can be int or String ("unlimited")
  final int totalCallMinutesAvailable;
  final int limitCallMinutes;
  final int usedChatbotPrompts;
  final dynamic balanceChatbotPrompts; // Can be int or String ("unlimited")
  final dynamic totalChatbotPromptsAvailable; // Can be int or String ("unlimited")
  final dynamic limitChatbotPrompts; // Can be int or String ("unlimited")

  MonthlyUsage({
    required this.usedCallMinutes,
    required this.balanceCallMinutes,
    required this.totalCallMinutesAvailable,
    required this.limitCallMinutes,
    required this.usedChatbotPrompts,
    required this.balanceChatbotPrompts,
    required this.totalChatbotPromptsAvailable,
    required this.limitChatbotPrompts,
  });

  factory MonthlyUsage.fromJson(Map<String, dynamic> json) {
    return MonthlyUsage(
      usedCallMinutes: json['used_call_minutes'] as int? ?? 0,
      balanceCallMinutes: json['balance_call_minutes'],
      totalCallMinutesAvailable: json['total_call_minutes_available'] as int? ?? 0,
      limitCallMinutes: json['limit_call_minutes'] as int? ?? 0,
      usedChatbotPrompts: json['used_chatbot_prompts'] as int? ?? 0,
      balanceChatbotPrompts: json['balance_chatbot_prompts'],
      totalChatbotPromptsAvailable: json['total_chatbot_prompts_available'],
      limitChatbotPrompts: json['limit_chatbot_prompts'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used_call_minutes': usedCallMinutes,
      'balance_call_minutes': balanceCallMinutes,
      'total_call_minutes_available': totalCallMinutesAvailable,
      'limit_call_minutes': limitCallMinutes,
      'used_chatbot_prompts': usedChatbotPrompts,
      'balance_chatbot_prompts': balanceChatbotPrompts,
      'total_chatbot_prompts_available': totalChatbotPromptsAvailable,
      'limit_chatbot_prompts': limitChatbotPrompts,
    };
  }
}

class DailyUsage {
  final int usedCallMinutes;
  final int remainingCallMinutes;
  final int callLimitPerDay;
  final int usedChatbotPrompts;
  final dynamic remainingChatbotPrompts; // Can be int or String ("unlimited")
  final int chatbotPromptLimit;

  DailyUsage({
    required this.usedCallMinutes,
    required this.remainingCallMinutes,
    required this.callLimitPerDay,
    required this.usedChatbotPrompts,
    required this.remainingChatbotPrompts,
    required this.chatbotPromptLimit,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      usedCallMinutes: json['used_call_minutes'] as int? ?? 0,
      remainingCallMinutes: json['remaining_call_minutes'] as int? ?? 0,
      callLimitPerDay: json['call_limit_per_day'] as int? ?? 0,
      usedChatbotPrompts: json['used_chatbot_prompts'] as int? ?? 0,
      remainingChatbotPrompts: json['remaining_chatbot_prompts'],
      chatbotPromptLimit: json['chatbot_prompt_limit'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used_call_minutes': usedCallMinutes,
      'remaining_call_minutes': remainingCallMinutes,
      'call_limit_per_day': callLimitPerDay,
      'used_chatbot_prompts': usedChatbotPrompts,
      'remaining_chatbot_prompts': remainingChatbotPrompts,
      'chatbot_prompt_limit': chatbotPromptLimit,
    };
  }
}
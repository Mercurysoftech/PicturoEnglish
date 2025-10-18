class PlanInfoResponse {
  final bool status;
  final List<ChatBotPlanInfo> planInfo;

  PlanInfoResponse({
    required this.status,
    required this.planInfo,
  });

  factory PlanInfoResponse.fromJson(Map<String, dynamic> json) {
    return PlanInfoResponse(
      status: json['status'] as bool? ?? false,
      planInfo: json['plan_info'] != null
          ? (json['plan_info'] as List)
              .map((item) => ChatBotPlanInfo.fromJson(item as Map<String, dynamic>))
              .toList()
          : <ChatBotPlanInfo>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'plan_info': planInfo.map((item) => item.toJson()).toList(),
    };
  }
}

class ChatBotPlanInfo {
  final int id;
  final int userId;
  final bool planActive;
  final String planType;
  final double dailyLimit;
  final double totalBudget;
  final int totalTokensAvailable;
  final int tokensUsed;
  final int tokensRemaining;
  final double usedToday;
  final double remainingBudget;
  final int estimatedConversationsLeft;
  final String planStartDate;
  final String planEndDate;
  final String lastUpdated;

  ChatBotPlanInfo({
    required this.id,
    required this.userId,
    required this.planActive,
    required this.planType,
    required this.dailyLimit,
    required this.totalBudget,
    required this.totalTokensAvailable,
    required this.tokensUsed,
    required this.tokensRemaining,
    required this.usedToday,
    required this.remainingBudget,
    required this.estimatedConversationsLeft,
    required this.planStartDate,
    required this.planEndDate,
    required this.lastUpdated,
  });

  factory ChatBotPlanInfo.fromJson(Map<String, dynamic> json) {
    return ChatBotPlanInfo(
      id: _safeParseInt(json['id']) ?? 0,
      userId: _safeParseInt(json['user_id']) ?? 0,
      planActive: _safeParseBool(json['plan_active']),
      planType: json['plan_type']?.toString() ?? '',
      dailyLimit: _safeParseDouble(json['daily_limit']) ?? 0.0,
      totalBudget: _safeParseDouble(json['total_budget']) ?? 0.0,
      totalTokensAvailable: _safeParseInt(json['total_tokens_available']) ?? 0,
      tokensUsed: _safeParseInt(json['tokens_used']) ?? 0,
      tokensRemaining: _safeParseInt(json['tokens_remaining']) ?? 0,
      usedToday: _safeParseDouble(json['used_today']) ?? 0.0,
      remainingBudget: _safeParseDouble(json['remaining_budget']) ?? 0.0,
      estimatedConversationsLeft:
          _safeParseInt(json['estimated_conversations_left']) ?? 0,
      planStartDate: json['plan_start_date']?.toString() ?? '',
      planEndDate: json['plan_end_date']?.toString() ?? '',
      lastUpdated: json['last_updated']?.toString() ?? '',
    );
  }

  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _safeParseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_active': planActive ? 1 : 0,
      'plan_type': planType,
      'daily_limit': dailyLimit.toStringAsFixed(2),
      'total_budget': totalBudget.toStringAsFixed(2),
      'total_tokens_available': totalTokensAvailable,
      'tokens_used': tokensUsed,
      'tokens_remaining': tokensRemaining,
      'used_today': usedToday.toStringAsFixed(2),
      'remaining_budget': remainingBudget.toStringAsFixed(2),
      'estimated_conversations_left': estimatedConversationsLeft,
      'plan_start_date': planStartDate,
      'plan_end_date': planEndDate,
      'last_updated': lastUpdated,
    };
  }
}

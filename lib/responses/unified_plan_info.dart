import 'package:picturo_app/responses/chatbot_plainfo_response.dart';
import 'package:picturo_app/services/chatbotapiservice.dart';

class UnifiedPlanInfo {
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

  UnifiedPlanInfo({
    this.id = 0,
    this.userId = 0,
    required this.planActive,
    required this.planType,
    required this.dailyLimit,
    this.totalBudget = 0.0,
    this.totalTokensAvailable = 0,
    this.tokensUsed = 0,
    this.tokensRemaining = 0,
    required this.usedToday,
    required this.remainingBudget,
    required this.estimatedConversationsLeft,
    this.planStartDate = '',
    this.planEndDate = '',
    this.lastUpdated = '',
  });

  factory UnifiedPlanInfo.fromChatBotPlanInfo(ChatBotPlanInfo info) {
    return UnifiedPlanInfo(
      id: info.id,
      userId: info.userId,
      planActive: info.planActive,
      planType: info.planType,
      dailyLimit: info.dailyLimit,
      totalBudget: info.totalBudget,
      totalTokensAvailable: info.totalTokensAvailable,
      tokensUsed: info.tokensUsed,
      tokensRemaining: info.tokensRemaining,
      usedToday: info.usedToday,
      remainingBudget: info.remainingBudget,
      estimatedConversationsLeft: info.estimatedConversationsLeft,
      planStartDate: info.planStartDate,
      planEndDate: info.planEndDate,
      lastUpdated: info.lastUpdated,
    );
  }

  factory UnifiedPlanInfo.fromPlanInfo(PlanInfo info) {
    return UnifiedPlanInfo(
      planActive: info.planActive,
      planType: info.planType,
      dailyLimit: info.dailyLimit,
      usedToday: info.usedToday,
      remainingBudget: info.remainingBudget,
      estimatedConversationsLeft: info.estimatedConversationsLeft,
    );
  }
}
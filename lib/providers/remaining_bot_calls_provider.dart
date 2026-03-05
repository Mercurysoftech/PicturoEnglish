import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picturo_app/services/chatbotapiservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemainingBotCallsProvider with ChangeNotifier {
  int _dailyRemainingMinutes = 0;
  int _monthlyRemainingMinutes = 0;
  dynamic _dailyRemainingPrompts = 0; 
  dynamic _monthlyRemainingPrompts = 0; 
  bool _isLoading = false;
  bool _isChatLoading = false;
  String? _error;
  String? _chatError;
  DateTime? _lastUpdated;
  bool _isUnlimitedCall = false;
  bool _isUnlimitedChat = false;
  int _estimatedConversationsLeft = 0;
  bool _planActive = false;
  String _planType = "";
  double _remainingBudget = 0.0;
  double _usedToday = 0.0;

  // Chatbot response related
  AiMultiLanguageResponseModel? _lastChatResponse;

  // Getters
  int get dailyRemainingMinutes => _dailyRemainingMinutes;
  int get monthlyRemainingMinutes => _monthlyRemainingMinutes;
  dynamic get dailyRemainingPrompts => _dailyRemainingPrompts;
  dynamic get monthlyRemainingPrompts => _monthlyRemainingPrompts;
  bool get isLoading => _isLoading;
  bool get isChatLoading => _isChatLoading;
  String? get error => _error;
  String? get chatError => _chatError;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isUnlimitedCall => _isUnlimitedCall;
  bool get isUnlimitedChat => _isUnlimitedChat;
  int get estimatedConversationsLeft => _estimatedConversationsLeft;
  bool get planActive => _planActive;
  String get planType => _planType;
  double get remainingBudget => _remainingBudget;
  double get usedToday => _usedToday;
  AiMultiLanguageResponseModel? get lastChatResponse => _lastChatResponse;

  // Check if prompts are unlimited
  bool get isDailyPromptsUnlimited => _dailyRemainingPrompts == "unlimited";
  bool get isMonthlyPromptsUnlimited => _monthlyRemainingPrompts == "unlimited";

  void _updateFromResponse(Map<String, dynamic> jsonData) {
    if (jsonData['status'] == true) {
      final oldDailyMinutes = _dailyRemainingMinutes;
      final oldMonthlyMinutes = _monthlyRemainingMinutes;

      // Update unlimited flags
      if (jsonData['merged_usage'] != null) {
        _isUnlimitedCall =
            jsonData['merged_usage']?['is_unlimited_call'] as bool? ?? false;
        _isUnlimitedChat =
            jsonData['merged_usage']?['is_unlimited_chat'] as bool? ?? false;
      }

      // Update monthly usage
      if (jsonData['merged_usage']?['monthly'] != null) {
        final monthly = jsonData['merged_usage']?['monthly'];
        _monthlyRemainingMinutes =
            _parseInt(monthly?['balance_call_minutes']) ?? 0;
        _monthlyRemainingPrompts = monthly?['balance_chatbot_prompts'] ?? 0;
      }

      // Update daily usage
      if (jsonData['merged_usage']?['daily'] != null) {
        final daily = jsonData['merged_usage']?['daily'];
        _dailyRemainingMinutes =
            _parseInt(daily?['remaining_call_minutes']) ?? 0;
        _dailyRemainingPrompts = daily?['remaining_chatbot_prompts'] ?? 0;
      }

      // Update plan info from chatbot response if available
      _updatePlanInfoFromChatResponse(jsonData);

      if (oldDailyMinutes != _dailyRemainingMinutes ||
          oldMonthlyMinutes != _monthlyRemainingMinutes) {
        notifyListeners();
      }
    }
  }

  // New method to update plan info from chatbot response
  void _updatePlanInfoFromChatResponse(Map<String, dynamic> jsonData) {
    // Check if we have plan info in the response
    if (jsonData['plan_info'] != null) {
      final planInfo = jsonData['plan_info'];
      _estimatedConversationsLeft =
          _parseInt(planInfo['estimated_conversations_left']) ?? 0;
      _planActive = planInfo['plan_active'] as bool? ?? false;
      _planType = planInfo['plan_type']?.toString() ?? "";
      _remainingBudget = _parseDouble(planInfo['remaining_budget']) ?? 0.0;
      _usedToday = _parseDouble(planInfo['used_today']) ?? 0.0;
    }
  }

  // Helper method to parse dynamic values to double
  double? _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Method to fetch remaining bot calls
  Future<void> fetchRemainingBotCalls() async {
    if (_isLoading ||
        (_lastUpdated != null &&
            DateTime.now().difference(_lastUpdated!).inSeconds < 10)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        _error = "No authentication token found";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse("https://picturoenglish.com/api/remaining-bot-call-view.php"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      print("Remaining Bot Calls API Response(from remaining bot calls provider): ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Update values from response
        _updateFromResponse(jsonData);
        _lastUpdated = DateTime.now();
        _error = null;
      } else {
        _error = "Failed to fetch data. Status code: ${response.statusCode}";
        print("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _error = "Error fetching remaining bot calls: $e";
      print("Error fetching remaining bot calls: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to get chatbot response and update remaining prompts
  Future<AiMultiLanguageResponseModel?> getChatbotResponse({
    required String message,
    required String language,
    required String scenario,
  }) async {
    // Check if user can use chatbot
    if (!canUseChatbot) {
      _chatError = "No remaining prompts available";
      notifyListeners();
      return null;
    }

    _isChatLoading = true;
    _chatError = null;
    notifyListeners();

    try {
      final chatbotService = await ChatBotApiService.create();
      final response = await chatbotService.getChatbotResponse(
        message: message,
        language: language,
        scenario: scenario,
      );

      // Update last chat response
      _lastChatResponse = response;

      // Update plan info from response
      if (response.planInfo != null) {
        _estimatedConversationsLeft =
            response.planInfo!.estimatedConversationsLeft;
        _planActive = response.planInfo!.planActive;
        _planType = response.planInfo!.planType;
        _remainingBudget = response.planInfo!.remainingBudget;
        _usedToday = response.planInfo!.usedToday;
      }

      // If there's an error in the response
      if (response.error != null && response.error!.isNotEmpty) {
        _chatError = response.error;
        _isChatLoading = false;
        notifyListeners();
        return response;
      }

      // Decrement daily prompts if not unlimited and response was successful
      if (!_isUnlimitedChat && response.error == null) {
        decrementDailyPrompts();
      }

      _isChatLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _chatError = "Error getting chatbot response: $e";
      _isChatLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Helper method to parse dynamic values to int
  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Method to manually update values (for testing or when you know they changed)
  void updateValues({
    int? dailyMinutes,
    int? monthlyMinutes,
    dynamic dailyPrompts,
    dynamic monthlyPrompts,
    bool? isUnlimitedCall,
    bool? isUnlimitedChat,
  }) {
    if (dailyMinutes != null) _dailyRemainingMinutes = dailyMinutes;
    if (monthlyMinutes != null) _monthlyRemainingMinutes = monthlyMinutes;
    if (dailyPrompts != null) _dailyRemainingPrompts = dailyPrompts;
    if (monthlyPrompts != null) _monthlyRemainingPrompts = monthlyPrompts;
    if (isUnlimitedCall != null) _isUnlimitedCall = isUnlimitedCall;
    if (isUnlimitedChat != null) _isUnlimitedChat = isUnlimitedChat;
    notifyListeners();
  }

  // Method to decrement daily minutes (when a call is made)
  void decrementDailyMinutes(int minutesUsed) {
    if (!_isUnlimitedCall) {
      _dailyRemainingMinutes = (_dailyRemainingMinutes - minutesUsed)
          .clamp(0, _dailyRemainingMinutes);
      notifyListeners();
    }
  }

  // Method to decrement daily prompts (when a prompt is used)
  void decrementDailyPrompts() {
    if (!_isUnlimitedChat && _dailyRemainingPrompts is int) {
      _dailyRemainingPrompts =
          ((_dailyRemainingPrompts as int) - 1).clamp(0, 1 << 31);
      notifyListeners();
    }
  }

  // Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearChatError() {
    _chatError = null;
    notifyListeners();
  }

  // Clear last chat response
  void clearLastChatResponse() {
    _lastChatResponse = null;
    notifyListeners();
  }

  // Check if user can make calls (has remaining minutes or is unlimited)
  bool get canMakeCall {
    return _isUnlimitedCall || _dailyRemainingMinutes > 0;
  }

  // Check if user can use chatbot (has remaining prompts or is unlimited)
  bool get canUseChatbot {
    return _isUnlimitedChat ||
        (_dailyRemainingPrompts is int && _dailyRemainingPrompts > 0) ||
        _dailyRemainingPrompts == "unlimited";
  }

  // Get formatted remaining prompts text
  String get formattedDailyPrompts {
    if (_dailyRemainingPrompts == "unlimited") {
      return "Unlimited";
    } else if (_dailyRemainingPrompts is int) {
      return _dailyRemainingPrompts.toString();
    }
    return "0";
  }

  // Get formatted monthly prompts text
  String get formattedMonthlyPrompts {
    if (_monthlyRemainingPrompts == "unlimited") {
      return "Unlimited";
    } else if (_monthlyRemainingPrompts is int) {
      return _monthlyRemainingPrompts.toString();
    }
    return "0";
  }
}

class PlanModel {
  int? id;
  String? name;
  String? description;
  String? type;
  String? validityDays;
  int? callLimitPerDay;
  String? chatbotPromptLimit;
  int? isUnlimitedCall;
  int? isUnlimitedChat;
  String? price;
  String? createdAt;
  String? updatedAt;
  String? priceIcon;
  String? priceAndValid;

  PlanModel({
    this.id,
    this.name,
    this.description,
    this.type,
    this.validityDays,
    this.callLimitPerDay,
    this.chatbotPromptLimit,
    this.isUnlimitedCall,
    this.isUnlimitedChat,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.priceIcon,
    this.priceAndValid,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      validityDays: json['validity_days']?.toString() ?? '',
      callLimitPerDay: json['call_limit_per_day'] ?? 0,
      chatbotPromptLimit: json['chatbot_prompt_limit']?.toString() ?? '',
      isUnlimitedCall: json['is_unlimited_call'] ?? 0,
      isUnlimitedChat: json['is_unlimited_chat'] ?? 0,
      price: json['price']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      priceIcon: json['price_icon']?.toString() ?? '',
      priceAndValid: json['price_and_valid']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['type'] = type;
    data['validity_days'] = validityDays;
    data['call_limit_per_day'] = callLimitPerDay;
    data['chatbot_prompt_limit'] = chatbotPromptLimit;
    data['is_unlimited_call'] = isUnlimitedCall;
    data['is_unlimited_chat'] = isUnlimitedChat;
    data['price'] = price;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['price_icon'] = priceIcon;
    data['price_and_valid'] = priceAndValid;
    return data;
  }

  // Static method to parse the entire API response
  static PlanResponse parsePlanResponse(Map<String, dynamic> json) {
    return PlanResponse(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => PlanModel.fromJson(item))
          .toList() ?? [],
    );
  }
}

class PlanResponse {
  final bool status;
  final List<PlanModel> data;

  PlanResponse({
    required this.status,
    required this.data,
  });
}
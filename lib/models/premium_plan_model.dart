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

  PlanModel(
      {this.id,
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
        this.updatedAt});
  PlanModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    name = json['name']?.toString() ?? '';
    description = json['description']?.toString() ?? '';
    type = json['type']?.toString() ?? '';
    validityDays = json['validity_days']?.toString() ?? '';
    callLimitPerDay = json['call_limit_per_day'] ?? 0;
    chatbotPromptLimit = json['chatbot_prompt_limit']?.toString() ?? '';
    isUnlimitedCall = json['is_unlimited_call'] ?? 0;
    isUnlimitedChat = json['is_unlimited_chat'] ?? 0;
    price = json['price']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['type'] = this.type;
    data['validity_days'] = this.validityDays;
    data['call_limit_per_day'] = this.callLimitPerDay;
    data['chatbot_prompt_limit'] = this.chatbotPromptLimit;
    data['is_unlimited_call'] = this.isUnlimitedCall;
    data['is_unlimited_chat'] = this.isUnlimitedChat;
    data['price'] = this.price;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

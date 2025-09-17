class UserResponse {
  final bool status;
  final User user;
  final Wallet wallet;

  UserResponse({
    required this.status,
    required this.user,
    required this.wallet,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      status: json["status"] ?? false,
      user: User.fromJson(json["user"] ?? {}),
      wallet: Wallet.fromJson(json["wallet"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "user": user.toJson(),
      "wallet": wallet.toJson(),
    };
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final int mobile;
  final String password;
  final int age;
  final String gender;
  final String speakingLevel;
  final String location;
  final String membership;
  final String referralCode;
  final String reason;
  final String speakingLanguage;
  final String qualification;
  final int avatarId;
  final String? verifyCode;
  final String? userSupport;
  final String? createdAt;
  final String? fcmToken;
  final String? activeRefferalCode;
  final int? planId;
  final String? activePlanDate;
  final String? planVoicecall;
  final int? planVoicecallUsed;
  final String? planMessage;
  final String? planGames;
  final String? planChatbot;
  final String? planStartTime;
  final String? planEndTime;
  final String? balanceRupees;
  final int totalTokensUsed;
  final String? referredBy;
  final String? prevPlanVoicecall;
  final String? prevPlanStartTime;
  final String? prevPlanEndTime;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.mobile,
    required this.password,
    required this.age,
    required this.gender,
    required this.speakingLevel,
    required this.location,
    required this.membership,
    required this.referralCode,
    required this.reason,
    required this.speakingLanguage,
    required this.qualification,
    required this.avatarId,
    this.verifyCode,
    this.userSupport,
    this.createdAt,
    this.fcmToken,
    this.activeRefferalCode,
    this.planId,
    this.activePlanDate,
    this.planVoicecall,
    this.planVoicecallUsed,
    this.planMessage,
    this.planGames,
    this.planChatbot,
    this.planStartTime,
    this.planEndTime,
    this.balanceRupees,
    required this.totalTokensUsed,
    this.referredBy,
    this.prevPlanVoicecall,
    this.prevPlanStartTime,
    this.prevPlanEndTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] ?? 0,
      username: json["username"] ?? "",
      email: json["email"] ?? "",
      mobile: json["mobile"] ?? 0,
      password: json["password"] ?? "",
      age: json["age"] ?? 0,
      gender: json["gender"] ?? "",
      speakingLevel: json["speaking_level"] ?? "",
      location: json["location"] ?? "",
      membership: json["membership"] ?? "",
      referralCode: json["referral_code"] ?? "",
      reason: json["reason"] ?? '',
      speakingLanguage: json["speaking_language"] ?? "",
      qualification: json["qualification"] ?? "",
      avatarId: int.parse((json["avatar_id"] ?? 0).toString()),
      verifyCode: json["verify_code"],
      userSupport: json["user_support"],
      createdAt: json["created_at"],
      fcmToken: json["fcm_token"],
      activeRefferalCode: json["active_refferal_code"],
      planId: json["plan_id"],
      activePlanDate: json["active_plan_date"],
      planVoicecall: json["plan_voicecall"],
      planVoicecallUsed: json["plan_voicecall_used"] ?? 0,
      planMessage: json["plan_message"],
      planGames: json["plan_games"],
      planChatbot: json["plan_chatbot"],
      planStartTime: json["plan_start_time"],
      planEndTime: json["plan_end_time"],
      balanceRupees: json["balance_rupees"] ?? "0.00",
      totalTokensUsed: json["total_tokens_used"] ?? 0,
      referredBy: json["referred_by"],
      prevPlanVoicecall: json["prev_plan_voicecall"],
      prevPlanStartTime: json["prev_plan_start_time"],
      prevPlanEndTime: json["prev_plan_end_time"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "email": email,
      "mobile": mobile,
      "password": password,
      "age": age,
      "gender": gender,
      "speaking_level": speakingLevel,
      "location": location,
      "membership": membership,
      "referral_code": referralCode,
      "reason": reason,
      "speaking_language": speakingLanguage,
      "qualification": qualification,
      "avatar_id": avatarId,
      "verify_code": verifyCode,
      "user_support": userSupport,
      "created_at": createdAt,
      "fcm_token": fcmToken,
      "active_refferal_code": activeRefferalCode,
      "plan_id": planId,
      "active_plan_date": activePlanDate,
      "plan_voicecall": planVoicecall,
      "plan_voicecall_used": planVoicecallUsed,
      "plan_message": planMessage,
      "plan_games": planGames,
      "plan_chatbot": planChatbot,
      "plan_start_time": planStartTime,
      "plan_end_time": planEndTime,
      "balance_rupees": balanceRupees,
      "total_tokens_used": totalTokensUsed,
      "referred_by": referredBy,
      "prev_plan_voicecall": prevPlanVoicecall,
      "prev_plan_start_time": prevPlanStartTime,
      "prev_plan_end_time": prevPlanEndTime,
    };
  }
}

class Wallet {
  final int totalBalance;
  final List<Transaction?> transactions;

  Wallet({
    required this.totalBalance,
    required this.transactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    var transactionsList = json["transactions"] as List?;
    List<Transaction> transactions = transactionsList != null
        ? transactionsList.map((i) => Transaction.fromJson(i)).toList()
        : [];

    return Wallet(
      totalBalance: json["total_balance"] ?? 0,
      transactions: transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "total_balance": totalBalance,
      "transactions": transactions.map((e) => e?.toJson()).toList(),
    };
  }
}

class Transaction {
  final int? amount;
  final String? type;
  final String? description;
  final String? createdAt;

  Transaction({
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      amount: json["amount"] ?? 0,
      type: json["type"] ?? "",
      description: json["description"] ?? "",
      createdAt: json["created_at"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "type": type,
      "description": description,
      "created_at": createdAt,
    };
  }
}
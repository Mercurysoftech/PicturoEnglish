class ReferralEarnings {
  final bool status;
  final int userId;
  final int totalReferrals;
  final int totalEarned;
  final int walletBalance;

  ReferralEarnings({
    required this.status,
    required this.userId,
    required this.totalReferrals,
    required this.totalEarned,
    required this.walletBalance
  });

  factory ReferralEarnings.fromJson(Map<String, dynamic> json) {
    return ReferralEarnings(
      status: json['status'] ?? false,
      userId: json['user_id'] ?? 0,
      totalReferrals: json['total_referrals'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      walletBalance: json['wallet_balance'] ?? 0
    );
  }
}

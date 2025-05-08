class AvatarResponse {
  final bool status;
  final List<AvatarData> data;

  AvatarResponse({required this.status, required this.data});

  // Convert JSON map to AvatarResponse
  factory AvatarResponse.fromJson(Map<String, dynamic> json) {
    return AvatarResponse(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>).map((item) => AvatarData.fromJson(item)).toList(),
    );
  }
}

class AvatarData {
  final int id;
  final String avatarUrl;

  AvatarData({
    required this.id,
    required this.avatarUrl,
  });

  factory AvatarData.fromJson(Map<String, dynamic> json) {
    return AvatarData(
      id: json['avatar_id'],
      avatarUrl: json['avatar_url'], // Consider adding a base URL if needed
    );
  }
}

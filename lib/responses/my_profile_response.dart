class UserResponse {
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

  UserResponse({
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
    required this.avatarId
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json["id"],
      username: json["username"],
      email: json["email"],
      mobile: json["mobile"],
      password: json["password"],
      age: json["age"],
      gender: json["gender"],
      speakingLevel: json["speaking_level"],
      location: json["location"]??"",
      membership: json["membership"]??"",
      referralCode: json["referral_code"],
      reason: json["reason"]??'',
      speakingLanguage: json["speaking_language"] ?? "",
      qualification: json["qualification"] ?? "",
      avatarId: int.parse((json["avatar_id"] ?? 0).toString())
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
      "avatar_id":avatarId
    };
  }

}

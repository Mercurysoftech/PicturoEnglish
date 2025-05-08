class LanguageResponse {
  final bool status;
  final List<LanguageData> data;

  LanguageResponse({
    required this.status,
    required this.data,
  });

  // Factory method to parse JSON into a LanguageResponse object
  factory LanguageResponse.fromJson(Map<String, dynamic> json) {
    return LanguageResponse(
      status: json['status'],
      data: (json['data'] as List)
          .map((item) => LanguageData.fromJson(item))
          .toList(),
    );
  }
}

class LanguageData {
  final int id;
  final String language;
  final int countryId;

  LanguageData({
    required this.id,
    required this.language,
    required this.countryId,
  });

  // Factory method to parse JSON into a LanguageData object
  factory LanguageData.fromJson(Map<String, dynamic> json) {
    return LanguageData(
      id: json['id'],
      language: json['language'],
      countryId: json['country_id'],
    );
  }
}
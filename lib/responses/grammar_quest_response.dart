// grammar_quest_response.dart
class GrammarResponse {
  final bool isFreeHitUser;
  final bool isSubscribePlan;
  final int maxAllowedPercentage;
  final int progressPercentage;
  final int completedLevels;
  final int totalLevels;
  final List<GrammarQuestion> levels;

  GrammarResponse({
    required this.isFreeHitUser,
    required this.isSubscribePlan,
    required this.maxAllowedPercentage,
    required this.progressPercentage,
    required this.completedLevels,
    required this.totalLevels,
    required this.levels,
  });

  factory GrammarResponse.fromJson(Map<String, dynamic> json) {
    return GrammarResponse(
      isFreeHitUser: json['isfreehituser'] ?? false,
      isSubscribePlan: json['issubscribeplan'] ?? false,
      // Convert to int safely - handles both int and double
      maxAllowedPercentage: _toInt(json['max_allowed_percentage']),
      progressPercentage: _toInt(json['progress_percentage']),
      completedLevels: _toInt(json['completed_levels']),
      totalLevels: _toInt(json['total_levels']),
      levels: (json['levels'] as List<dynamic>?)
              ?.map((levelJson) => GrammarQuestion.fromJson(levelJson))
              .toList() ??
          [],
    );
  }

  // Helper method to safely convert dynamic to int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class GrammarQuestion {
  final int id;
  final String gameQus;
  final String imagePath;
  final int level;
  final bool completed;

  GrammarQuestion({
    required this.id,
    required this.gameQus,
    required this.imagePath,
    required this.level,
    required this.completed,
  });

  factory GrammarQuestion.fromJson(Map<String, dynamic> json) {
    return GrammarQuestion(
      id: _toInt(json['id']),
      gameQus: json['sentence'] ?? '',
      imagePath: json['image_path'] ?? '',
      level: _toInt(json['level']),
      completed: json['completed'] == true || json['completed'] == 1,
    );
  }

  // Helper method to safely convert dynamic to int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
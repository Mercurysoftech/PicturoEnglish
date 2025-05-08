class QuestionsResponse {
  final String? status;
  String? message;
  List<Question>? questions;

  QuestionsResponse({required this.status, this.message,
    this.questions});

  factory QuestionsResponse.fromJson(Map<String, dynamic> json) {
    return QuestionsResponse(
      status: json['status'],
       message: json['message'],
      questions: json['status'] == 'success'
          ? (json['questions'] as List)
              .map((e) => Question.fromJson(e))
              .toList()
          : null,
    );
  }
}

class Question {
  final int? id;
  final int? topicId;
  final String? question;
  final String? meaning;
  final String? example;
  final String? qusImage;

  Question({
    required this.id,
    required this.topicId,
    required this.question,
    required this.meaning,
    required this.example,
    required this.qusImage,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      topicId: json['topic_id'],
      question: json['question'],
      meaning: json['meaning'],
      example: json['example'],
      qusImage: json['qus_image'],
    );
  }
}

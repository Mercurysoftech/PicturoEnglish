class QuestionDetailsResponse {
  final String status;
  final String? message;
  final String? question;
  final String? meaning;
  final List<NativeMeaning> nativeMeaning;
  final String? example;
  final String? qusImage;
  final List<Example> examples;

  QuestionDetailsResponse({
    required this.status,
    this.message,
    this.question,
    this.meaning,
    required this.nativeMeaning,
    this.example,
    this.qusImage,
    required this.examples,
  });

  factory QuestionDetailsResponse.fromJson(Map<String, dynamic> json) {
    return QuestionDetailsResponse(
      status: json['status'] ?? '',
      message: json['message'],
      question: json['question'],
      meaning: json['meaning'],
      nativeMeaning: (json['native_meaning'] as List?)
          ?.map((e) => NativeMeaning.fromJson(e))
          .toList() ?? [],
      example: json['example'],
      qusImage: json['qus_image'],
      examples: (json['examples'] as List?)
          ?.map((e) => Example.fromJson(e))
          .toList() ?? [],
    );
  }
}

class NativeMeaning {
  final String? tamil;
  final String? hindi;
  final String? telugu;
  final String? malayalam;

  NativeMeaning({
    this.tamil,
    this.hindi,
    this.telugu,
    this.malayalam,
  });

  factory NativeMeaning.fromJson(Map<String, dynamic> json) {
    return NativeMeaning(
      tamil: json['tamil'],
      hindi: json['hindi'],
      telugu: json['telugu'],
      malayalam: json['malayalam'],
    );
  }

  Map<String, String?> toLanguageMap() {
    return {
      'Tamil': tamil,
      'Hindi': hindi,
      'Telugu': telugu,
      'Malayalam': malayalam,
    };
  }
}

class Example {
  final String? english;
  final String? hindi;
  final String? hindiNative;
  final String? tamil;
  final String? tamilNative;
  final String? telugu;
  final String? teluguNative;
  final String? malayalam;
  final String? malayalamNative;

  Example({
    this.english,
    this.hindi,
    this.hindiNative,
    this.tamil,
    this.tamilNative,
    this.telugu,
    this.teluguNative,
    this.malayalam,
    this.malayalamNative,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      english: json['english'],
      hindi: json['hindi'],
      hindiNative: json['hindi_native'],
      tamil: json['tamil'],
      tamilNative: json['tamil_native'],
      telugu: json['telugu'],
      teluguNative: json['telugu_native'],
      malayalam: json['malayalam'],
      malayalamNative: json['malayalam_native'],
    );
  }

  Map<String, String?> toLanguageMap() {
    return {
      'English': english,
      'Hindi': hindi,
      'Hindi (Native)': hindiNative,
      'Tamil': tamil,
      'Tamil (Native)': tamilNative,
      'Telugu': telugu,
      'Telugu (Native)': teluguNative,
      'Malayalam': malayalam,
      'Malayalam (Native)': malayalamNative,
    };
  }
}

class QuestionsListResponse {
  final String status;
  final String? message;
  final List<Question> questions;

  QuestionsListResponse({
    required this.status,
    this.message,
    required this.questions,
  });

  factory QuestionsListResponse.fromJson(Map<String, dynamic> json) {
    return QuestionsListResponse(
      status: json['status'] ?? '',
      message: json['message'],
      questions: (json['status'] == 'success' && json['questions'] != null)
          ? (json['questions'] as List).map((e) => Question.fromJson(e)).toList()
          : [],
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
    this.id,
    this.topicId,
    this.question,
    this.meaning,
    this.example,
    this.qusImage,
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

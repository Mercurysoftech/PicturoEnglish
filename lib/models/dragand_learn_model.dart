class DragAndLearnLevelModel {
  String? status;
  List<Data>? data;

  DragAndLearnLevelModel({this.status, this.data});

  DragAndLearnLevelModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? topicId;
  List<Levels>? levels;

  Data({this.topicId, this.levels});

  Data.fromJson(Map<String, dynamic> json) {
    topicId = json['topic_id'];
    if (json['levels'] != null) {
      levels = <Levels>[];
      json['levels'].forEach((v) {
        levels!.add(new Levels.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['topic_id'] = this.topicId;
    if (this.levels != null) {
      data['levels'] = this.levels!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Levels {
  int? level;
  bool? completed;
  List<Questions>? questions;

  Levels({this.level, this.completed, this.questions});

  Levels.fromJson(Map<String, dynamic> json) {
    level = json['level'];
    completed = json['completed'];
    if (json['questions'] != null) {
      questions = <Questions>[];
      json['questions'].forEach((v) {
        questions!.add(new Questions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['level'] = this.level;
    data['completed'] = this.completed;
    if (this.questions != null) {
      data['questions'] = this.questions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Questions {
  int? id;
  String? question;
  String? meaning;
  String? example;
  String? qusImage;

  Questions(
      {this.id, this.question, this.meaning, this.example, this.qusImage});

  Questions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    question = json['question'];
    meaning = json['meaning'];
    example = json['example'];
    qusImage = json['qus_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['question'] = this.question;
    data['meaning'] = this.meaning;
    data['example'] = this.example;
    data['qus_image'] = this.qusImage;
    return data;
  }
}

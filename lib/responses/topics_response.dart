class Topics {
  final int id;
  final String topicsName;
  final String topicsImage;
  final bool isCompleted;

  Topics({
    required this.id,
    required this.topicsName,
    required this.topicsImage,
    required this.isCompleted,
  });

  // Factory method to create a Book object from a JSON map
  factory Topics.fromJson(Map<String, dynamic> json) {
    return Topics(
      id: json['id'],
      topicsName: json['topics_name'],
      topicsImage: json['topics_image'],
      isCompleted:json['all_read'] ,
    );
  }
}

class TopicsResponse {
  final String status;
  final List<Topics> data;

  TopicsResponse({
    required this.status,
    required this.data,
  });

  // Factory method to create a BookResponse object from a JSON map
  factory TopicsResponse.fromJson(Map<String, dynamic> json) {
    var list = json['topics'] as List;
    List<Topics> booksList = list.map((i) => Topics.fromJson(i)).toList();

    return TopicsResponse(
      status: json['status'].toString(),
      data: booksList,
    );
  }
}
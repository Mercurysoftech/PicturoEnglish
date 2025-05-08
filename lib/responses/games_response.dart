class Games {
  final int id;
  final String gameName;
  final String gameDate;

  Games({
    required this.id,
    required this.gameName,
    required this.gameDate,
  });

  // Factory method to create a Book object from a JSON map
  factory Games.fromJson(Map<String, dynamic> json) {
    return Games(
      id: json['id'],
      gameName: json['game_name'],
      gameDate: json['date'],
    );
  }
}

class GamesResponse {
  final bool status;
  final List<Games> data;

  GamesResponse({
    required this.status,
    required this.data,
  });

  // Factory method to create a BookResponse object from a JSON map
  factory GamesResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<Games> booksList = list.map((i) => Games.fromJson(i)).toList();

    return GamesResponse(
      status: json['status'],
      data: booksList,
    );
  }
}
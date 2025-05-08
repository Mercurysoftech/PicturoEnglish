class Book {
  final int id;
  final String booksName;
  final String booksDate;

  Book({
    required this.id,
    required this.booksName,
    required this.booksDate,
  });

  // Factory method to create a Book object from a JSON map
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      booksName: json['books_name'],
      booksDate: json['books_date'],
    );
  }
}

class BookResponse {
  final bool status;
  final List<Book> data;

  BookResponse({
    required this.status,
    required this.data,
  });

  // Factory method to create a BookResponse object from a JSON map
  factory BookResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<Book> booksList = list.map((i) => Book.fromJson(i)).toList();

    return BookResponse(
      status: json['status'],
      data: booksList,
    );
  }
}
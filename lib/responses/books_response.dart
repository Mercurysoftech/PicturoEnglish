class Book {
  final int id;
  final String booksName;
  final String? booksImage;
  final String booksDate;

  Book({
    required this.id,
    required this.booksName,
    required this.booksDate,
    this.booksImage,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int? ?? 0,
      booksName: json['books_name'] as String? ?? '',
      booksImage: json['books_image'] as String?,
      booksDate: json['books_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'books_name': booksName,
      'books_image': booksImage,
      'books_date': booksDate,
    };
  }

  bool get hasImage => booksImage != null && booksImage!.isNotEmpty;

  bool get isComingSoon {
    final name = booksName.toLowerCase();
    return name.contains('coming soon') || name.contains('comming soon');
  }

   String get fullImageUrl {
    if (!hasImage) return '';
    final imagePath = booksImage!;
    final cleanPath = imagePath.startsWith('/') 
        ? imagePath.substring(1) 
        : imagePath;
    return 'https://picturoenglish.com/admin/$cleanPath';
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
    // Handle case where data might not be a list or might be null
    final dataList = json['data'];
    List<Book> booksList = [];

    if (dataList is List) {
      booksList = dataList.map((i) => Book.fromJson(i)).toList();
    }

    return BookResponse(
      status: json['status'] as bool? ?? false,
      data: booksList,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((book) => book.toJson()).toList(),
    };
  }

  // Helper method to check if response has data
  bool get hasData => data.isNotEmpty;
}

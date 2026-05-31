import 'book.dart';

class BookshelfItem {
  final String id;
  final Book book;
  final String addedAt;
  final int sortOrder;

  BookshelfItem({
    required this.id,
    required this.book,
    required this.addedAt,
    required this.sortOrder,
  });

  factory BookshelfItem.fromJson(Map<String, dynamic> json) {
    return BookshelfItem(
      id: json['id'] as String,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      addedAt: json['addedAt'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }
}

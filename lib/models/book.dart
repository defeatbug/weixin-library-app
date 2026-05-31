class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? coverUrl;
  final String fileUrl;
  final String fileType;
  final String? description;
  final String? publisher;
  final String? publishedAt;
  final String? language;
  final double fileSizeBytes;
  final double? averageRating;
  final int reviewCount;
  final String createdAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.coverUrl,
    required this.fileUrl,
    required this.fileType,
    this.description,
    this.publisher,
    this.publishedAt,
    this.language,
    required this.fileSizeBytes,
    this.averageRating,
    required this.reviewCount,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String?,
      coverUrl: json['coverUrl'] as String?,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedAt: json['publishedAt'] as String?,
      language: json['language'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num).toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'isbn': isbn,
    'coverUrl': coverUrl,
    'fileUrl': fileUrl,
    'fileType': fileType,
    'description': description,
    'publisher': publisher,
    'publishedAt': publishedAt,
    'language': language,
    'fileSizeBytes': fileSizeBytes,
    'averageRating': averageRating,
    'reviewCount': reviewCount,
    'createdAt': createdAt,
  };
}

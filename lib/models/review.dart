class Review {
  final String id;
  final ReviewUser user;
  final ReviewBook book;
  final int rating;
  final String? content;
  final String createdAt;
  final String updatedAt;

  Review({
    required this.id,
    required this.user,
    required this.book,
    required this.rating,
    this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      user: ReviewUser.fromJson(json['user'] as Map<String, dynamic>),
      book: ReviewBook.fromJson(json['book'] as Map<String, dynamic>),
      rating: json['rating'] as int,
      content: json['content'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class ReviewUser {
  final String id;
  final String displayName;
  final String? avatarUrl;

  ReviewUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class ReviewBook {
  final String id;
  final String title;

  ReviewBook({required this.id, required this.title});

  factory ReviewBook.fromJson(Map<String, dynamic> json) {
    return ReviewBook(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }
}

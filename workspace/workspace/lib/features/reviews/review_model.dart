class ReviewModel {
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final int createdAt;

  const ReviewModel({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String userId, Map<dynamic, dynamic> map) {
    return ReviewModel(
      userId: userId,
      userName: (map['userName'] ?? '') as String,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: (map['comment'] ?? '') as String,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };
}

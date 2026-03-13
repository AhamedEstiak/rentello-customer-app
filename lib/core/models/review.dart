/// Review for display (from GET) or submit (POST body uses rating, comment only).
class Review {
  final String? id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final bool? isApproved;

  const Review({
    this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    this.isApproved,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String?,
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : null,
        isApproved: json['isApproved'] as bool?,
      );

  /// For POST body: { "rating": 1..5, "comment": "..." }
  Map<String, dynamic> toJson() => {
        'rating': rating,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}

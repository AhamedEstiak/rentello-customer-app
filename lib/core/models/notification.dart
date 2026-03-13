class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final DateTime? readAt;
  final String? bookingId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.readAt,
    this.bookingId,
    this.metadata,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        readAt: json['readAt'] != null
            ? DateTime.parse(json['readAt'].toString())
            : null,
        bookingId: json['bookingId'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );

  bool get isRead => readAt != null;
}

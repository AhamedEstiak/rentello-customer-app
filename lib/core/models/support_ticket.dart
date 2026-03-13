class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final String message;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.message,
    this.bookingId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'].toString());
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'].toString())
        : createdAt;
    return SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
      bookingId: json['bookingId'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

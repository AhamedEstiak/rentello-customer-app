class PaymentEntry {
  final String id;
  final String type;
  final double amount;
  final String method;
  final String? reference;
  final String? description;
  final DateTime createdAt;

  const PaymentEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.method,
    this.reference,
    this.description,
    required this.createdAt,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        method: json['method'] as String,
        reference: json['reference'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}

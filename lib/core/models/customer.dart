class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final int totalTrips;
  final double totalSpent;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.totalTrips,
    required this.totalSpent,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        address: json['address'] as String?,
        totalTrips: json['totalTrips'] as int? ?? 0,
        totalSpent: double.parse(json['totalSpent']?.toString() ?? '0'),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get loyaltyTier {
    if (totalTrips >= 50 || totalSpent >= 500000) return 'VIP';
    if (totalTrips >= 20 || totalSpent >= 150000) return 'Gold';
    if (totalTrips >= 5 || totalSpent >= 30000) return 'Silver';
    return 'Regular';
  }

  Customer copyWith({
    String? name,
    String? email,
    String? address,
  }) =>
      Customer(
        id: id,
        name: name ?? this.name,
        phone: phone,
        email: email ?? this.email,
        address: address ?? this.address,
        totalTrips: totalTrips,
        totalSpent: totalSpent,
        createdAt: createdAt,
      );
}

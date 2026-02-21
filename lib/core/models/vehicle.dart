class Vehicle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String category;
  final String? color;
  final int seats;
  final String fuelType;
  final String transmission;
  final List<String> imageUrls;
  final double pricePerDay;
  final double? pricePerHour;
  final double? pricePerKm;

  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.category,
    this.color,
    required this.seats,
    required this.fuelType,
    required this.transmission,
    required this.imageUrls,
    required this.pricePerDay,
    this.pricePerHour,
    this.pricePerKm,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        category: json['category'] as String,
        color: json['color'] as String?,
        seats: json['seats'] as int? ?? 4,
        fuelType: json['fuelType'] as String? ?? 'Petrol',
        transmission: json['transmission'] as String? ?? 'Automatic',
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        pricePerDay: double.parse(json['pricePerDay'].toString()),
        pricePerHour: json['pricePerHour'] != null
            ? double.parse(json['pricePerHour'].toString())
            : null,
        pricePerKm: json['pricePerKm'] != null
            ? double.parse(json['pricePerKm'].toString())
            : null,
      );

  String get displayName => '$brand $model';
}

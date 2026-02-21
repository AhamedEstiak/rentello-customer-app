class BookingVehicle {
  final String brand;
  final String model;
  final String category;
  final List<String> imageUrls;

  const BookingVehicle({
    required this.brand,
    required this.model,
    required this.category,
    required this.imageUrls,
  });

  factory BookingVehicle.fromJson(Map<String, dynamic> json) => BookingVehicle(
        brand: json['brand'] as String,
        model: json['model'] as String,
        category: json['category'] as String,
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class BookingStatusEntry {
  final String toStatus;
  final String? note;
  final DateTime changedAt;

  const BookingStatusEntry({
    required this.toStatus,
    this.note,
    required this.changedAt,
  });

  factory BookingStatusEntry.fromJson(Map<String, dynamic> json) =>
      BookingStatusEntry(
        toStatus: json['toStatus'] as String,
        note: json['note'] as String?,
        changedAt: DateTime.parse(json['changedAt'] as String),
      );
}

class FareBreakdown {
  final int baseFare;
  final int hourlyCharge;
  final int distanceCharge;
  final int nightSurcharge;
  final int airportSurcharge;
  final int intercitySurcharge;
  final int subtotal;
  final int discount;
  final int totalAmount;

  const FareBreakdown({
    required this.baseFare,
    required this.hourlyCharge,
    required this.distanceCharge,
    required this.nightSurcharge,
    required this.airportSurcharge,
    required this.intercitySurcharge,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) => FareBreakdown(
        baseFare: (json['baseFare'] as num).toInt(),
        hourlyCharge: (json['hourlyCharge'] as num).toInt(),
        distanceCharge: (json['distanceCharge'] as num).toInt(),
        nightSurcharge: (json['nightSurcharge'] as num).toInt(),
        airportSurcharge: (json['airportSurcharge'] as num).toInt(),
        intercitySurcharge: (json['intercitySurcharge'] as num).toInt(),
        subtotal: (json['subtotal'] as num).toInt(),
        discount: (json['discount'] as num).toInt(),
        totalAmount: (json['totalAmount'] as num).toInt(),
      );
}

class Booking {
  final String id;
  final String bookingNumber;
  final String type;
  final String status;
  final String paymentStatus;
  final String pickupAddress;
  final String? dropoffAddress;
  final DateTime scheduledPickup;
  final DateTime? scheduledDropoff;
  final double totalAmount;
  final double paidAmount;
  final DateTime createdAt;
  final BookingVehicle? vehicle;
  final List<BookingStatusEntry> statusLog;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.type,
    required this.status,
    required this.paymentStatus,
    required this.pickupAddress,
    this.dropoffAddress,
    required this.scheduledPickup,
    this.scheduledDropoff,
    required this.totalAmount,
    required this.paidAmount,
    required this.createdAt,
    this.vehicle,
    this.statusLog = const [],
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        bookingNumber: json['bookingNumber'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
        paymentStatus: json['paymentStatus'] as String,
        pickupAddress: json['pickupAddress'] as String,
        dropoffAddress: json['dropoffAddress'] as String?,
        scheduledPickup: DateTime.parse(json['scheduledPickup'] as String),
        scheduledDropoff: json['scheduledDropoff'] != null
            ? DateTime.parse(json['scheduledDropoff'] as String)
            : null,
        totalAmount: double.parse(json['totalAmount']?.toString() ?? '0'),
        paidAmount: double.parse(json['paidAmount']?.toString() ?? '0'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        vehicle: json['vehicle'] != null
            ? BookingVehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
            : null,
        statusLog: (json['statusLog'] as List<dynamic>?)
                ?.map((e) =>
                    BookingStatusEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class IntercityRoute {
  final String id;
  final String name;
  final String originZone;
  final String destinationZone;
  final double distanceKm;
  final double estimatedHours;
  final double basePriceSedan;
  final double basePriceSuv;
  final double basePriceMicrobus;
  final double basePricePremium;

  const IntercityRoute({
    required this.id,
    required this.name,
    required this.originZone,
    required this.destinationZone,
    required this.distanceKm,
    required this.estimatedHours,
    required this.basePriceSedan,
    required this.basePriceSuv,
    required this.basePriceMicrobus,
    required this.basePricePremium,
  });

  factory IntercityRoute.fromJson(Map<String, dynamic> json) => IntercityRoute(
        id: json['id'] as String,
        name: json['name'] as String,
        originZone: json['originZone'] as String,
        destinationZone: json['destinationZone'] as String,
        distanceKm: double.parse(json['distanceKm'].toString()),
        estimatedHours: double.parse(json['estimatedHours'].toString()),
        basePriceSedan: double.parse(json['basePriceSedan'].toString()),
        basePriceSuv: double.parse(json['basePriceSuv'].toString()),
        basePriceMicrobus: double.parse(json['basePriceMicrobus'].toString()),
        basePricePremium: double.parse(json['basePricePremium'].toString()),
      );

  String get displayName => '$originZone → $destinationZone';
}

class BookingVehicle {
  final String? id;
  final String brand;
  final String model;
  final String category;
  final List<String> imageUrls;
  final String? registrationNo;
  final int? seats;
  final String? fuelType;
  final String? transmission;

  const BookingVehicle({
    this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.imageUrls,
    this.registrationNo,
    this.seats,
    this.fuelType,
    this.transmission,
  });

  factory BookingVehicle.fromJson(Map<String, dynamic> json) {
    final List<String> urls;
    if (json['imageUrls'] != null && json['imageUrls'] is List) {
      urls = (json['imageUrls'] as List<dynamic>).map((e) => e.toString()).toList();
    } else if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      urls = [json['imageUrl'].toString()];
    } else {
      urls = [];
    }
    return BookingVehicle(
      id: json['id'] as String?,
      brand: json['brand'] as String,
      model: json['model'] as String,
      category: json['category'] as String,
      imageUrls: urls,
      registrationNo: json['registrationNo'] as String?,
      seats: json['seats'] as int?,
      fuelType: json['fuelType'] as String?,
      transmission: json['transmission'] as String?,
    );
  }
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

class BookingPrice {
  final double baseFare;
  final double surcharges;
  final double discount;
  final double taxes;
  final double totalAmount;
  final double paidAmount;

  const BookingPrice({
    required this.baseFare,
    required this.surcharges,
    required this.discount,
    required this.taxes,
    required this.totalAmount,
    required this.paidAmount,
  });

  factory BookingPrice.fromJson(Map<String, dynamic> json) => BookingPrice(
        baseFare: _toDouble(json['baseFare']),
        surcharges: _toDouble(json['surcharges']),
        discount: _toDouble(json['discount']),
        taxes: _toDouble(json['taxes']),
        totalAmount: _toDouble(json['totalAmount']),
        paidAmount: _toDouble(json['paidAmount']),
      );
}

class BookingDriver {
  final String id;
  final String name;
  final String phone;

  const BookingDriver({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory BookingDriver.fromJson(Map<String, dynamic> json) => BookingDriver(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
      );
}

class BookingRoute {
  final String id;
  final String name;

  const BookingRoute({
    required this.id,
    required this.name,
  });

  factory BookingRoute.fromJson(Map<String, dynamic> json) => BookingRoute(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class BookingReview {
  final String id;
  final int rating;
  final String? comment;

  const BookingReview({
    required this.id,
    required this.rating,
    this.comment,
  });

  factory BookingReview.fromJson(Map<String, dynamic> json) => BookingReview(
        id: json['id'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
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

  /// Parses backend fare-estimate breakdown keys: baseFare, hourlyCharge,
  /// distanceCharge, nightSurcharge, airportSurcharge, intercitySurcharge,
  /// subtotal, discount, totalAmount. Uses 0 for missing or null values.
  factory FareBreakdown.fromJson(Map<String, dynamic> json) => FareBreakdown(
        baseFare: _numToInt(json['baseFare']),
        hourlyCharge: _numToInt(json['hourlyCharge']),
        distanceCharge: _numToInt(json['distanceCharge']),
        nightSurcharge: _numToInt(json['nightSurcharge']),
        airportSurcharge: _numToInt(json['airportSurcharge']),
        intercitySurcharge: _numToInt(json['intercitySurcharge']),
        subtotal: _numToInt(json['subtotal']),
        discount: _numToInt(json['discount']),
        totalAmount: _numToInt(json['totalAmount']),
      );
}

int _numToInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is int) return value;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class Booking {
  final String id;
  final String bookingNumber;
  final String type;
  final String status;
  final String? paymentStatus;
  final String pickupAddress;
  final String? dropoffAddress;
  final DateTime scheduledPickup;
  final DateTime? scheduledDropoff;
  final double totalAmount;
  final double paidAmount;
  final DateTime? createdAt;
  final BookingVehicle? vehicle;
  final List<BookingStatusEntry> statusLog;
  final BookingPrice? price;
  final BookingDriver? driver;
  final BookingRoute? route;
  final BookingReview? review;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.type,
    required this.status,
    this.paymentStatus,
    required this.pickupAddress,
    this.dropoffAddress,
    required this.scheduledPickup,
    this.scheduledDropoff,
    required this.totalAmount,
    required this.paidAmount,
    this.createdAt,
    this.vehicle,
    this.statusLog = const [],
    this.price,
    this.driver,
    this.route,
    this.review,
  });

  /// Resolved payment status: from top-level field or derived from price/amounts.
  String get effectivePaymentStatus {
    if (paymentStatus != null && paymentStatus!.isNotEmpty) return paymentStatus!;
    if (price != null) {
      if (price!.paidAmount >= price!.totalAmount) return 'PAID';
      if (price!.paidAmount > 0) return 'PARTIAL';
      return 'UNPAID';
    }
    if (paidAmount >= totalAmount) return 'PAID';
    if (paidAmount > 0) return 'PARTIAL';
    return 'UNPAID';
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickupTime'] ?? json['scheduledPickup'];
    final scheduledPickup = pickup != null ? DateTime.parse(pickup.toString()) : DateTime.now();
    final total = _toDouble(json['totalAmount']);
    final paid = _toDouble(json['paidAmount']);
    String? paymentStatusRes = json['paymentStatus'] as String?;
    if (paymentStatusRes == null && json['price'] != null) {
      final p = json['price'] as Map<String, dynamic>;
      final pTotal = _toDouble(p['totalAmount']);
      final pPaid = _toDouble(p['paidAmount']);
      if (pPaid >= pTotal) {
        paymentStatusRes = 'PAID';
      } else if (pPaid > 0) {
        paymentStatusRes = 'PARTIAL';
      } else {
        paymentStatusRes = 'UNPAID';
      }
    }
    return Booking(
      id: json['id'] as String,
      bookingNumber: json['bookingNumber'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      paymentStatus: paymentStatusRes,
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String?,
      scheduledPickup: scheduledPickup,
      scheduledDropoff: json['scheduledDropoff'] != null
          ? DateTime.parse(json['scheduledDropoff'].toString())
          : null,
      totalAmount: total,
      paidAmount: paid,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      vehicle: json['vehicle'] != null
          ? BookingVehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      statusLog: (json['statusLog'] as List<dynamic>?)
              ?.map((e) =>
                  BookingStatusEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      price: json['price'] != null
          ? BookingPrice.fromJson(json['price'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? BookingDriver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      route: json['route'] != null
          ? BookingRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      review: json['review'] != null
          ? BookingReview.fromJson(json['review'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationInfo {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => PaginationInfo(
        page: (json['page'] as num).toInt(),
        pageSize: (json['pageSize'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
      );
}

class BookingsResponse {
  final List<Booking> data;
  final PaginationInfo pagination;

  const BookingsResponse({
    required this.data,
    required this.pagination,
  });

  factory BookingsResponse.fromJson(Map<String, dynamic> json) => BookingsResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: PaginationInfo.fromJson(
            json['pagination'] as Map<String, dynamic>),
      );
}

class IntercityRoute {
  final String id;
  final String name;
  final String originZone;
  final String destinationZone;
  final String? originUpazilaId;
  final String? destinationUpazilaId;
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
    this.originUpazilaId,
    this.destinationUpazilaId,
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
        originUpazilaId: json['originUpazilaId'] as String?,
        destinationUpazilaId: json['destinationUpazilaId'] as String?,
        distanceKm: double.parse(json['distanceKm'].toString()),
        estimatedHours: double.parse(json['estimatedHours'].toString()),
        basePriceSedan: double.parse(json['basePriceSedan'].toString()),
        basePriceSuv: double.parse(json['basePriceSuv'].toString()),
        basePriceMicrobus: double.parse(json['basePriceMicrobus'].toString()),
        basePricePremium: double.parse(json['basePricePremium'].toString()),
      );

  String get displayName => '$originZone → $destinationZone';
}

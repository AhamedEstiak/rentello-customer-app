class VehicleType {
  final String label;
  /// Matches `Vehicle.category` from the API (e.g. SEDAN, SUV).
  final String categoryCode;

  const VehicleType({
    required this.label,
    required this.categoryCode,
  });
}

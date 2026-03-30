import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

/// Server-aligned category metadata (`/vehicle-categories` → `categories`).
class VehicleCategoryInfo {
  final String value;
  final String label;

  const VehicleCategoryInfo({required this.value, required this.label});

  factory VehicleCategoryInfo.fromJson(Map<String, dynamic> json) {
    final v = json['value'];
    final l = json['label'];
    final value = v == null ? '' : v.toString();
    final label = l == null ? '' : l.toString();
    return VehicleCategoryInfo(
      value: value,
      label: label.isNotEmpty ? label : value,
    );
  }
}

/// Fallback when unauthenticated, request fails, or payload is invalid (matches `VEHICLE_CATEGORIES` in car-rent360).
const kDefaultVehicleCategories = <VehicleCategoryInfo>[
  VehicleCategoryInfo(value: 'SEDAN', label: 'Sedan'),
  VehicleCategoryInfo(value: 'SUV', label: 'SUV'),
  VehicleCategoryInfo(value: 'MICROBUS', label: 'Microbus'),
  VehicleCategoryInfo(value: 'PREMIUM', label: 'Premium'),
  VehicleCategoryInfo(value: 'HIACE', label: 'Hiace'),
];

List<VehicleCategoryInfo>? _parseCategories(Map<String, dynamic>? data) {
  final raw = data?['categories'];
  if (raw is! List || raw.isEmpty) return null;
  final out = <VehicleCategoryInfo>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final info = VehicleCategoryInfo.fromJson(m);
    if (info.value.isEmpty) continue;
    out.add(info);
  }
  return out.isEmpty ? null : out;
}

final vehicleCategoriesProvider =
    FutureProvider<List<VehicleCategoryInfo>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return kDefaultVehicleCategories;
  }

  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.vehicleCategories);
    final parsed = _parseCategories(res.data);
    if (parsed != null) return parsed;
    return kDefaultVehicleCategories;
  } catch (_) {
    return kDefaultVehicleCategories;
  }
});

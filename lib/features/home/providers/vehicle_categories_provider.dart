import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

/// Server-aligned category metadata (`/vehicle-categories` → `categories`).
class VehicleCategoryInfo {
  final String value;
  final String label;
  /// `vehicle_types.id` when the API returns it; prefer for fare/booking payloads.
  final String? id;

  const VehicleCategoryInfo({
    required this.value,
    required this.label,
    this.id,
  });

  factory VehicleCategoryInfo.fromJson(Map<String, dynamic> json) {
    final v = json['value'];
    final l = json['label'];
    final rawId = json['id'];
    final value = v == null ? '' : v.toString();
    final label = l == null ? '' : l.toString();
    String? id;
    if (rawId != null) {
      final s = rawId.toString().trim();
      if (s.isNotEmpty) id = s;
    }
    return VehicleCategoryInfo(
      value: value,
      label: label.isNotEmpty ? label : value,
      id: id,
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

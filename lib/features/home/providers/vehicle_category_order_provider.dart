import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

/// Fallback if the request fails or returns empty (matches previous client default).
const kDefaultVehicleCategoryOrder = [
  'SEDAN',
  'SUV',
  'MICROBUS',
  'PREMIUM',
];

final vehicleCategoryOrderProvider = FutureProvider<List<String>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return kDefaultVehicleCategoryOrder;
  }

  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.vehicleCategories);
    final raw = res.data?['categoryOrder'];
    if (raw is! List || raw.isEmpty) {
      return kDefaultVehicleCategoryOrder;
    }
    return raw.map((e) => e.toString()).toList();
  } catch (_) {
    return kDefaultVehicleCategoryOrder;
  }
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/locations.dart';

/// [forPickup] selects `districtsPickup` vs `districtsDestination` from the API.
final locationsProvider =
    FutureProvider.family<List<DistrictLocation>, bool>((ref, forPickup) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.locations);

  dynamic data = res.data;
  List<dynamic> districtsRaw;

  if (data is Map<String, dynamic>) {
    final map = data;
    final primaryKey =
        forPickup ? 'districtsPickup' : 'districtsDestination';
    districtsRaw = (map[primaryKey] ??
            map['districts'] ??
            map['locations'] ??
            map['data'] ??
            <dynamic>[]) as List<dynamic>;
  } else if (data is List<dynamic>) {
    districtsRaw = data;
  } else {
    districtsRaw = <dynamic>[];
  }

  return districtsRaw
      .whereType<Map<String, dynamic>>()
      .map(DistrictLocation.fromJson)
      .toList();
});

/// [forPickup] fetches active pickup points when true, destination points when false.
final flatLocationsProvider =
    FutureProvider.family<List<LocationItem>, bool>((ref, forPickup) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(
    ApiEndpoints.locations,
    queryParameters: {
      'isActive': 'true',
      'isPickupPoint': forPickup ? 'true' : 'false',
    },
  );

  final data = res.data;
  List<dynamic> raw;
  if (data is List) {
    raw = data;
  } else if (data is Map<String, dynamic>) {
    raw = (data['data'] ?? data['locations'] ?? data['items'] ?? <dynamic>[])
        as List<dynamic>;
  } else {
    raw = <dynamic>[];
  }

  return raw
      .whereType<Map<String, dynamic>>()
      .map(LocationItem.fromJson)
      .toList();
});


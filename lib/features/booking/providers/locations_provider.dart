import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/locations.dart';

final locationsProvider =
    FutureProvider<List<DistrictLocation>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.locations);

  dynamic data = res.data;
  List<dynamic> districtsRaw;

  if (data is Map<String, dynamic>) {
    districtsRaw = (data['districts'] ??
            data['locations'] ??
            data['data'] ??
            <dynamic>[])
        as List<dynamic>;
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


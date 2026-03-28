import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/vehicle.dart';
import '../../auth/providers/auth_provider.dart';

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void select(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
        SelectedCategoryNotifier.new);

final vehicleListProvider =
    FutureProvider.family<List<Vehicle>, String>((ref, category) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return <Vehicle>[];
  }

  final dio = ref.watch(dioProvider);
  final params =
      category != 'ALL' ? {'category': category} : <String, dynamic>{};

  final res = await dio.get(
    ApiEndpoints.vehicles,
    queryParameters: params.isNotEmpty ? params : null,
  );

  final list = res.data['vehicles'] as List<dynamic>;
  return list
      .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
      .toList();
});

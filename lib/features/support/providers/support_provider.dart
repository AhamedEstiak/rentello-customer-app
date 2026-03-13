import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/support_ticket.dart';

/// Optional query for support tickets list.
class SupportTicketsQuery {
  final String? status;
  final int limit;

  const SupportTicketsQuery({this.status, this.limit = 20});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportTicketsQuery &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(status, limit);
}

final supportTicketsProvider =
    FutureProvider.family<List<SupportTicket>, SupportTicketsQuery>(
        (ref, query) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(
    ApiEndpoints.supportTickets,
    queryParameters: {
      if (query.status != null && query.status!.isNotEmpty) 'status': query.status,
      'limit': query.limit.clamp(1, 100),
    },
  );
  final list = res.data['tickets'] as List<dynamic>? ?? [];
  return list
      .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
      .toList();
});

const _defaultSupportQuery = SupportTicketsQuery();

final defaultSupportTicketsProvider =
    supportTicketsProvider(_defaultSupportQuery);

/// Creates a support ticket and invalidates the list.
Future<SupportTicket> createSupportTicket(
  WidgetRef ref, {
  required String subject,
  required String message,
  String? bookingId,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post(
    ApiEndpoints.supportTickets,
    data: {
      'subject': subject,
      'message': message,
      if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
    },
  );
  ref.invalidate(supportTicketsProvider);
  return SupportTicket.fromJson(res.data as Map<String, dynamic>);
}

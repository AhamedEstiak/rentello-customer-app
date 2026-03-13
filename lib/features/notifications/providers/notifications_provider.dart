import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/notification.dart';

/// Optional query for notifications list.
class NotificationsQuery {
  final bool unreadOnly;
  final int limit;

  const NotificationsQuery({this.unreadOnly = false, this.limit = 50});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationsQuery &&
          runtimeType == other.runtimeType &&
          unreadOnly == other.unreadOnly &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(unreadOnly, limit);
}

final notificationsProvider = FutureProvider.family<List<AppNotification>,
    NotificationsQuery>((ref, query) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(
    ApiEndpoints.notifications,
    queryParameters: {
      if (query.unreadOnly) 'unreadOnly': 'true',
      'limit': query.limit.clamp(1, 100),
    },
  );
  final list = res.data['notifications'] as List<dynamic>? ?? [];
  return list
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Default query for the notifications list screen.
const _defaultQuery = NotificationsQuery();

/// Convenience provider for the default notifications list.
final defaultNotificationsProvider =
    notificationsProvider(_defaultQuery);

/// Marks a notification as read and invalidates the list.
Future<void> ackNotification(WidgetRef ref, String id) async {
  final dio = ref.read(dioProvider);
  await dio.post(ApiEndpoints.notificationAck(id));
  ref.invalidate(notificationsProvider);
}

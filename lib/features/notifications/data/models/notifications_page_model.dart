import '../../domain/entities/notifications_page.dart';
import '../json_parsers.dart';
import 'notification_model.dart';

/// Tolerant page model for `GET /api/notifications`. The documented shape is a
/// paged envelope `{ data:[...], totalCount, pageNumber, pageSize, totalPages }`,
/// but a bare array `[{...}]` is also accepted defensively:
///   • a bare array       → `hasMore` inferred from a full page
///   • a paged object     → `hasMore` = `pageNumber < totalPages`
class NotificationsPageModel {
  final List<NotificationModel> items;
  final bool hasMore;

  const NotificationsPageModel({
    required this.items,
    required this.hasMore,
  });

  /// [data] is the unwrapped payload (`response['data']`) — a `List` or a
  /// paged `Map`. [pageSize] lets the bare-array branch infer `hasMore`.
  factory NotificationsPageModel.fromData(
    Object? data, {
    required int pageSize,
  }) {
    if (data is List) {
      final rows = parseMapList(data)
          .map(NotificationModel.fromJson)
          .toList(growable: false);
      return NotificationsPageModel(
        items: rows,
        hasMore: rows.length >= pageSize,
      );
    }
    final map = parseNullableMap(data) ?? const <String, dynamic>{};
    final rows = parseMapList(map['data'])
        .map(NotificationModel.fromJson)
        .toList(growable: false);
    final pageNumber = parseInt(map['pageNumber'], fallback: 1);
    final totalPages = parseInt(map['totalPages'], fallback: 1);
    return NotificationsPageModel(
      items: rows,
      hasMore: pageNumber < totalPages,
    );
  }

  NotificationsPage toEntity() => NotificationsPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        hasMore: hasMore,
      );
}

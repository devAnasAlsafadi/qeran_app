import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_notifications_page.dart';
import 'matchmaker_notification_model.dart';

/// Tolerant page model for `GET /api/notifications`. The doc shows a bare array
/// `[{...}]`, yet the endpoint takes `page`/`pageSize` — so this accepts BOTH:
///   • a bare array            → `hasMore` inferred from a full page
///   • a paginated object      → `{ data:[...], pageNumber, totalPages }`
class MatchmakerNotificationsPageModel {
  final List<MatchmakerNotificationModel> items;
  final bool hasMore;

  const MatchmakerNotificationsPageModel({
    required this.items,
    required this.hasMore,
  });

  /// [data] is the unwrapped payload (`response['data']`) — a `List` or a
  /// paginated `Map`. [pageSize] lets the bare-array branch infer `hasMore`.
  factory MatchmakerNotificationsPageModel.fromData(
    Object? data, {
    required int pageSize,
  }) {
    if (data is List) {
      final rows = parseMapList(data)
          .map(MatchmakerNotificationModel.fromJson)
          .toList(growable: false);
      return MatchmakerNotificationsPageModel(
        items: rows,
        hasMore: rows.length >= pageSize,
      );
    }
    final map = parseNullableMap(data) ?? const <String, dynamic>{};
    final rows = parseMapList(map['data'])
        .map(MatchmakerNotificationModel.fromJson)
        .toList(growable: false);
    final pageNumber = parseInt(map['pageNumber'], fallback: 1);
    final totalPages = parseInt(map['totalPages'], fallback: 1);
    return MatchmakerNotificationsPageModel(
      items: rows,
      hasMore: pageNumber < totalPages,
    );
  }

  MatchmakerNotificationsPage toEntity() => MatchmakerNotificationsPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        hasMore: hasMore,
      );
}

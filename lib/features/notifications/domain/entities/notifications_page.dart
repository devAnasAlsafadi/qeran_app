import 'package:equatable/equatable.dart';

import 'notification_item.dart';

/// One page of inbox notifications. The endpoint's shape varies (a bare array
/// or a paged envelope), so [hasMore] is resolved in the data layer rather than
/// derived from page numbers here.
class NotificationsPage extends Equatable {
  final List<NotificationItem> items;
  final bool hasMore;

  const NotificationsPage({
    required this.items,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, hasMore];
}

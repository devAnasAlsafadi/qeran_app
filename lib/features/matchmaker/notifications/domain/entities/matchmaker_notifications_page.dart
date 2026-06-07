import 'package:equatable/equatable.dart';

import 'matchmaker_notification.dart';

/// One page of inbox notifications. The endpoint's shape varies (a bare array
/// or a paged envelope), so [hasMore] is resolved in the data layer rather than
/// derived from page numbers here.
class MatchmakerNotificationsPage extends Equatable {
  final List<MatchmakerNotification> items;
  final bool hasMore;

  const MatchmakerNotificationsPage({
    required this.items,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, hasMore];
}

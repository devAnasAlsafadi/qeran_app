import 'package:flutter/material.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import '../../domain/entities/matchmaker_users_list.dart';

/// Three-segment header for the Users tab — a thin typed wrapper over the
/// shared [MatchmakerSegmentedTabs]. The Pending segment carries the count
/// badge fed from the dashboard.
class MatchmakerUsersSegmentedTabs extends StatelessWidget {
  const MatchmakerUsersSegmentedTabs({
    super.key,
    required this.active,
    required this.onChanged,
    this.pendingBadge = 0,
  });

  final MatchmakerUsersList active;
  final ValueChanged<MatchmakerUsersList> onChanged;
  final int pendingBadge;

  static const List<MatchmakerUsersList> _order = [
    MatchmakerUsersList.pending,
    MatchmakerUsersList.approvedUnsubscribed,
    MatchmakerUsersList.approvedSubscribed,
  ];

  @override
  Widget build(BuildContext context) {
    return MatchmakerSegmentedTabs(
      activeIndex: _order.indexOf(active),
      onChanged: (i) => onChanged(_order[i]),
      segments: [
        MatchmakerSegment(
          labelKey: LocaleKeys.matchmaker_users_tab_pending,
          badge: pendingBadge,
        ),
        const MatchmakerSegment(
          labelKey: LocaleKeys.matchmaker_users_tab_approved_unsubscribed,
        ),
        const MatchmakerSegment(
          labelKey: LocaleKeys.matchmaker_users_tab_approved_subscribed,
        ),
      ],
    );
  }
}

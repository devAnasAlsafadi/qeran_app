import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Builds the 5-item `QeranBottomNav` for the Matchmaker shell.
///
/// Reuses the exact design-system nav (curved-notch, gold disc, deep
/// recess) — only the items differ from the user app. Index order is
/// fixed and consumed by `MatchmakerHomeScreen.IndexedStack`:
///   0 = Dashboard
///   1 = Users
///   2 = Compatibility cases
///   3 = Conversations
///   4 = Explore
class MatchmakerBottomNav extends StatelessWidget {
  const MatchmakerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <QeranNavItem>[
      QeranNavItem(
        outlineIcon: Icons.dashboard_outlined,
        filledIcon: Icons.dashboard_rounded,
        label: LocaleKeys.matchmaker_nav_dashboard.t(context),
      ),
      QeranNavItem(
        outlineIcon: Icons.groups_2_outlined,
        filledIcon: Icons.groups_2_rounded,
        label: LocaleKeys.matchmaker_nav_users.t(context),
      ),
      QeranNavItem(
        outlineIcon: Icons.handshake_outlined,
        filledIcon: Icons.handshake_rounded,
        label: LocaleKeys.matchmaker_nav_cases.t(context),
      ),
      QeranNavItem(
        outlineIcon: Icons.chat_bubble_outline_rounded,
        filledIcon: Icons.chat_bubble_rounded,
        label: LocaleKeys.matchmaker_nav_conversations.t(context),
      ),
      QeranNavItem(
        outlineIcon: Icons.travel_explore_outlined,
        filledIcon: Icons.travel_explore_rounded,
        label: LocaleKeys.matchmaker_nav_explore.t(context),
      ),
    ];
    return QeranBottomNav(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}

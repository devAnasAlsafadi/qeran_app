import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../badges/domain/entities/badge_counts.dart';
import '../../../../badges/presentation/blocs/badges_cubit.dart';

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
    return BlocBuilder<BadgesCubit, BadgeCounts>(
      bloc: sl<BadgesCubit>(),
      builder: (context, badges) => QeranBottomNav(
        items: _items(context, badges),
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }

  /// Dots, not numbers — the user app's nav reads the same way.
  ///
  /// Dashboard and Explore carry none: the backend documents both as
  /// permanently zero, and a tab that can never light must not wear a badge
  /// implying it might.
  ///
  /// The Users dot is NOT the «بالانتظار» count inside that screen. That one
  /// is a standing workload figure on the sub-tab; this one says something has
  /// changed since you last looked. Different surfaces, different questions.
  List<QeranNavItem> _items(BuildContext context, BadgeCounts badges) {
    return <QeranNavItem>[
      QeranNavItem(
        outlineIcon: Icons.dashboard_outlined,
        filledIcon: Icons.dashboard_rounded,
        label: LocaleKeys.matchmaker_nav_dashboard.t(context),
      ),
      QeranNavItem(
        outlineIcon: Icons.groups_2_outlined,
        filledIcon: Icons.groups_2_rounded,
        label: LocaleKeys.matchmaker_nav_users.t(context),
        badgeCount: badges.users,
        badgeIsDot: true,
      ),
      QeranNavItem(
        outlineIcon: Icons.handshake_outlined,
        filledIcon: Icons.handshake_rounded,
        label: LocaleKeys.matchmaker_nav_cases.t(context),
        badgeCount: badges.cases,
        badgeIsDot: true,
      ),
      QeranNavItem(
        outlineIcon: Icons.chat_bubble_outline_rounded,
        filledIcon: Icons.chat_bubble_rounded,
        label: LocaleKeys.matchmaker_nav_conversations.t(context),
        badgeCount: badges.conversations,
        badgeIsDot: true,
      ),
      QeranNavItem(
        outlineIcon: Icons.travel_explore_outlined,
        filledIcon: Icons.travel_explore_rounded,
        label: LocaleKeys.matchmaker_nav_explore.t(context),
      ),
    ];
  }
}

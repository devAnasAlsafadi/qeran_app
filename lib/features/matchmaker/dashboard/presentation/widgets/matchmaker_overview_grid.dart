import 'package:flutter/material.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../domain/entities/matchmaker_dashboard_stats.dart';
import 'matchmaker_dashboard_tabs.dart';
import 'matchmaker_overview_tile.dart';

/// «نظرة عامة»: the four overview tiles, two by two.
class MatchmakerOverviewGrid extends StatelessWidget {
  const MatchmakerOverviewGrid({
    super.key,
    required this.stats,
    required this.onOpen,
  });

  final MatchmakerDashboardStats stats;
  final MatchmakerOpenTab onOpen;

  @override
  Widget build(BuildContext context) {
    final tiles = [..._approvedTiles(context), ..._otherTiles(context)];
    return GridView.count(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: QeranSpacing.s12,
      crossAxisSpacing: QeranSpacing.s12,
      childAspectRatio: 1.2,
      children: [
        for (var i = 0; i < tiles.length; i++)
          SoftScaleIn(
            duration: QeranMotion.standard,
            delay: QeranMotion.staggerStep * (i + 2),
            child: tiles[i],
          ),
      ],
    );
  }

  /// The two approved counts, each leading to its Users sub-tab.
  List<Widget> _approvedTiles(BuildContext context) => [
    _tile(
      context,
      Icons.workspace_premium_outlined,
      stats.approvedSubscribedCount,
      LocaleKeys.matchmaker_dashboard_approved_subscribed,
      MatchmakerUsersList.approvedSubscribed,
    ),
    _tile(
      context,
      Icons.verified_outlined,
      stats.approvedUnsubscribedCount,
      LocaleKeys.matchmaker_dashboard_approved_unsubscribed,
      MatchmakerUsersList.approvedUnsubscribed,
    ),
  ];

  /// Active cases (Cases) and everyone assigned to her (Users).
  List<Widget> _otherTiles(BuildContext context) => [
    MatchmakerOverviewTile(
      icon: Icons.handshake_outlined,
      count: stats.activeCompatibilityCasesCount,
      label: LocaleKeys.matchmaker_dashboard_active_cases.t(context),
      onTap: () => onOpen(MatchmakerDashboardTabs.cases),
    ),
    MatchmakerOverviewTile(
      icon: Icons.groups_2_outlined,
      count: stats.totalAssignedUsers,
      label: LocaleKeys.matchmaker_dashboard_total_assigned.t(context),
      onTap: () => onOpen(MatchmakerDashboardTabs.users),
    ),
  ];

  Widget _tile(
    BuildContext context,
    IconData icon,
    int count,
    String labelKey,
    MatchmakerUsersList usersSubTab,
  ) => MatchmakerOverviewTile(
    icon: icon,
    count: count,
    label: labelKey.t(context),
    onTap: () =>
        onOpen(MatchmakerDashboardTabs.users, usersSubTab: usersSubTab),
  );
}

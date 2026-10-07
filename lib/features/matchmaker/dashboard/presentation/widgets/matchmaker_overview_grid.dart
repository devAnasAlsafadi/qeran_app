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
    final tiles = <Widget>[
      MatchmakerOverviewTile(
        icon: Icons.workspace_premium_outlined,
        count: stats.approvedSubscribedCount,
        label: LocaleKeys.matchmaker_dashboard_approved_subscribed.t(context),
        onTap: () => onOpen(MatchmakerDashboardTabs.users,
            usersSubTab: MatchmakerUsersList.approvedSubscribed),
      ),
      MatchmakerOverviewTile(
        icon: Icons.verified_outlined,
        count: stats.approvedUnsubscribedCount,
        label: LocaleKeys.matchmaker_dashboard_approved_unsubscribed.t(context),
        onTap: () => onOpen(MatchmakerDashboardTabs.users,
            usersSubTab: MatchmakerUsersList.approvedUnsubscribed),
      ),
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
}

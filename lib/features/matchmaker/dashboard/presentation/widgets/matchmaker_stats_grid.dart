import 'package:flutter/material.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../domain/entities/matchmaker_dashboard_stats.dart';
import 'matchmaker_stat_card.dart';

/// Destination tab indices in `MatchmakerHomeScreen`'s IndexedStack.
/// 0=dashboard · 1=users · 2=cases · 3=conversations · 4=explore.
const int _usersTab = 1;
const int _casesTab = 2;
const int _conversationsTab = 3;

/// Descriptor for one stat card: icon, label, which count to read, the
/// destination tab a tap opens, and (for the three user counts) the
/// Users sub-tab to land on.
class _StatSpec {
  final IconData icon;
  final String labelKey;
  final int Function(MatchmakerDashboardStats s) count;
  final int destinationTab;
  final MatchmakerUsersList? usersSubTab;
  const _StatSpec(
    this.icon,
    this.labelKey,
    this.count,
    this.destinationTab, {
    this.usersSubTab,
  });
}

const List<_StatSpec> _specs = [
  _StatSpec(Icons.pending_actions_outlined,
      LocaleKeys.matchmaker_dashboard_pending, _pending, _usersTab,
      usersSubTab: MatchmakerUsersList.pending),
  _StatSpec(Icons.workspace_premium_outlined,
      LocaleKeys.matchmaker_dashboard_approved_subscribed, _approvedSub,
      _usersTab, usersSubTab: MatchmakerUsersList.approvedSubscribed),
  _StatSpec(Icons.verified_outlined,
      LocaleKeys.matchmaker_dashboard_approved_unsubscribed, _approvedUnsub,
      _usersTab, usersSubTab: MatchmakerUsersList.approvedUnsubscribed),
  _StatSpec(Icons.handshake_outlined,
      LocaleKeys.matchmaker_dashboard_active_cases, _activeCases, _casesTab),
  _StatSpec(Icons.mark_chat_unread_outlined,
      LocaleKeys.matchmaker_dashboard_unread_messages, _unread,
      _conversationsTab),
  _StatSpec(Icons.groups_2_outlined,
      LocaleKeys.matchmaker_dashboard_total_assigned, _total, _usersTab),
];

int _pending(MatchmakerDashboardStats s) => s.pendingUsersCount;
int _approvedSub(MatchmakerDashboardStats s) => s.approvedSubscribedCount;
int _approvedUnsub(MatchmakerDashboardStats s) => s.approvedUnsubscribedCount;
int _activeCases(MatchmakerDashboardStats s) => s.activeCompatibilityCasesCount;
int _unread(MatchmakerDashboardStats s) => s.unreadMessagesCount;
int _total(MatchmakerDashboardStats s) => s.totalAssignedUsers;

const EdgeInsets _gridPadding =
    EdgeInsets.fromLTRB(QeranSpacing.s20, QeranSpacing.s16, QeranSpacing.s20,
        QeranSpacing.s32);

/// The 6-counter grid. Each card reveals with the signature soft
/// scale-in, staggered by position. Scrollable so the parent's
/// `RefreshIndicator` can drive pull-to-refresh.
class MatchmakerStatsGrid extends StatelessWidget {
  const MatchmakerStatsGrid({
    super.key,
    required this.stats,
    required this.onOpen,
  });

  final MatchmakerDashboardStats stats;
  final MatchmakerOpenTab onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: _gridPadding,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      crossAxisCount: 2,
      mainAxisSpacing: QeranSpacing.s16,
      crossAxisSpacing: QeranSpacing.s16,
      childAspectRatio: 0.96,
      children: [
        for (var i = 0; i < _specs.length; i++)
          SoftScaleIn(
            duration: QeranMotion.standard,
            delay: QeranMotion.staggerStep * i,
            child: MatchmakerStatCard(
              icon: _specs[i].icon,
              count: _specs[i].count(stats),
              label: _specs[i].labelKey.t(context),
              onTap: () => onOpen(
                _specs[i].destinationTab,
                usersSubTab: _specs[i].usersSubTab,
              ),
            ),
          ),
      ],
    );
  }
}

/// Skeleton placeholder shown while the first fetch is in flight. Mirrors
/// the 2-column card rhythm with warm-cream shimmer boxes (never grey).
class MatchmakerStatsGridSkeleton extends StatelessWidget {
  const MatchmakerStatsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: _gridPadding,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: QeranSpacing.s16,
      crossAxisSpacing: QeranSpacing.s16,
      childAspectRatio: 0.96,
      children: List.generate(
        6,
        (_) => const QeranSkeleton.box(
          height: double.infinity,
          radius: QeranRadii.card,
        ),
        growable: false,
      ),
    );
  }
}

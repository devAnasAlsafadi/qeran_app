import 'package:flutter/material.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../domain/entities/matchmaker_dashboard_stats.dart';
import 'matchmaker_attention_card.dart';
import 'matchmaker_greeting_row.dart';
import 'matchmaker_overview_tile.dart';

/// Destination tab indices in `MatchmakerHomeScreen`'s IndexedStack.
/// 0=dashboard · 1=users · 2=cases · 3=conversations · 4=explore.
const int _usersTab = 1;
const int _casesTab = 2;
const int _conversationsTab = 3;

/// Skeleton hero-block height — approximates the live cards' natural
/// (content-sized) height so the loading state matches the loaded layout.
const double _heroHeight = 170;

/// The dashboard content — greeting, the two attention heroes, and the
/// 2×2 overview grid. The six counters and their destinations are
/// unchanged; only the presentation is redesigned. Scrollable so the
/// parent `RefreshIndicator` can drive pull-to-refresh.
class MatchmakerDashboardBody extends StatelessWidget {
  const MatchmakerDashboardBody({
    super.key,
    required this.stats,
    required this.matchmakerName,
    required this.onOpen,
  });

  final MatchmakerDashboardStats stats;

  /// Cached session name (may be null/empty → salaam-only greeting).
  final String? matchmakerName;

  final MatchmakerOpenTab onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranBottomNav.contentClearance(context),
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        MatchmakerGreetingRow(name: matchmakerName),
        QeranSpacing.vs24,
        QeranSectionHeader(
          title: LocaleKeys.matchmaker_dashboard_attention_title.t(context),
          subtitle:
              LocaleKeys.matchmaker_dashboard_attention_subtitle.t(context),
        ),
        QeranSpacing.vs12,
        // Content-sized; IntrinsicHeight keeps the two heroes equal-height
        // without clamping either to a fixed value (which overflowed).
        IntrinsicHeight(child: _AttentionRow(stats: stats, onOpen: onOpen)),
        QeranSpacing.vs24,
        QeranSectionHeader(
          title: LocaleKeys.matchmaker_dashboard_overview_title.t(context),
        ),
        QeranSpacing.vs12,
        _OverviewGrid(stats: stats, onOpen: onOpen),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.stats, required this.onOpen});

  final MatchmakerDashboardStats stats;
  final MatchmakerOpenTab onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SoftScaleIn(
            duration: QeranMotion.standard,
            child: MatchmakerAttentionCard(
              icon: Icons.pending_actions_outlined,
              count: stats.pendingUsersCount,
              label: LocaleKeys.matchmaker_dashboard_pending.t(context),
              actionLabel:
                  LocaleKeys.matchmaker_dashboard_hero_action.t(context),
              zeroLabel:
                  LocaleKeys.matchmaker_dashboard_pending_zero.t(context),
              onTap: () => onOpen(_usersTab,
                  usersSubTab: MatchmakerUsersList.pending),
            ),
          ),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: SoftScaleIn(
            duration: QeranMotion.standard,
            delay: QeranMotion.staggerStep,
            child: MatchmakerAttentionCard(
              icon: Icons.mark_chat_unread_outlined,
              count: stats.unreadMessagesCount,
              label: LocaleKeys.matchmaker_dashboard_unread_messages.t(context),
              actionLabel:
                  LocaleKeys.matchmaker_dashboard_hero_action.t(context),
              zeroLabel:
                  LocaleKeys.matchmaker_dashboard_unread_zero.t(context),
              onTap: () => onOpen(_conversationsTab),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.stats, required this.onOpen});

  final MatchmakerDashboardStats stats;
  final MatchmakerOpenTab onOpen;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      MatchmakerOverviewTile(
        icon: Icons.workspace_premium_outlined,
        count: stats.approvedSubscribedCount,
        label: LocaleKeys.matchmaker_dashboard_approved_subscribed.t(context),
        onTap: () => onOpen(_usersTab,
            usersSubTab: MatchmakerUsersList.approvedSubscribed),
      ),
      MatchmakerOverviewTile(
        icon: Icons.verified_outlined,
        count: stats.approvedUnsubscribedCount,
        label: LocaleKeys.matchmaker_dashboard_approved_unsubscribed.t(context),
        onTap: () => onOpen(_usersTab,
            usersSubTab: MatchmakerUsersList.approvedUnsubscribed),
      ),
      MatchmakerOverviewTile(
        icon: Icons.handshake_outlined,
        count: stats.activeCompatibilityCasesCount,
        label: LocaleKeys.matchmaker_dashboard_active_cases.t(context),
        onTap: () => onOpen(_casesTab),
      ),
      MatchmakerOverviewTile(
        icon: Icons.groups_2_outlined,
        count: stats.totalAssignedUsers,
        label: LocaleKeys.matchmaker_dashboard_total_assigned.t(context),
        onTap: () => onOpen(_usersTab),
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

/// Skeleton shown during the first fetch — mirrors the redesigned layout:
/// a greeting line, a header bar, two tall hero blocks, and four tiles.
/// Warm-cream shimmer (never grey).
class MatchmakerDashboardBodySkeleton extends StatelessWidget {
  const MatchmakerDashboardBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranBottomNav.contentClearance(context),
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            const QeranSkeleton.circle(size: 48),
            QeranSpacing.hs12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const QeranSkeleton(width: 90, height: 10),
                  QeranSpacing.vs8,
                  const QeranSkeleton(width: 150, height: 18),
                ],
              ),
            ),
          ],
        ),
        QeranSpacing.vs24,
        const QeranSkeleton(width: 160, height: 20),
        QeranSpacing.vs12,
        const Row(
          children: [
            Expanded(
              child: QeranSkeleton.box(height: _heroHeight, radius: QeranRadii.panel),
            ),
            QeranSpacing.hs12,
            Expanded(
              child: QeranSkeleton.box(height: _heroHeight, radius: QeranRadii.panel),
            ),
          ],
        ),
        QeranSpacing.vs24,
        const QeranSkeleton(width: 120, height: 20),
        QeranSpacing.vs12,
        GridView.count(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: QeranSpacing.s12,
          crossAxisSpacing: QeranSpacing.s12,
          childAspectRatio: 1.2,
          children: List.generate(
            4,
            (_) => const QeranSkeleton.box(
              height: double.infinity,
              radius: QeranRadii.card,
            ),
            growable: false,
          ),
        ),
      ],
    );
  }
}

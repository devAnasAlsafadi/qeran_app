import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../community/presentation/widgets/dashboard/community_dashboard_section.dart';
import '../../domain/entities/matchmaker_dashboard_stats.dart';
import 'matchmaker_attention_row.dart';
import 'matchmaker_greeting_row.dart';
import 'matchmaker_overview_grid.dart';

/// The dashboard content — greeting, the two attention heroes, her
/// Community section (A2–A4), and the 2×2 overview grid. The six counters and their destinations are
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
        ..._attention(context),
        QeranSpacing.vs24,
        const CommunityDashboardSection(),
        QeranSpacing.vs24,
        QeranSectionHeader(
          title: LocaleKeys.matchmaker_dashboard_overview_title.t(context),
        ),
        QeranSpacing.vs12,
        MatchmakerOverviewGrid(stats: stats, onOpen: onOpen),
      ],
    );
  }

  /// «تحتاج انتباهك» and its two heroes.
  List<Widget> _attention(BuildContext context) => [
    QeranSectionHeader(
      title: LocaleKeys.matchmaker_dashboard_attention_title.t(context),
      subtitle: LocaleKeys.matchmaker_dashboard_attention_subtitle.t(context),
    ),
    QeranSpacing.vs12,
    // Content-sized; IntrinsicHeight keeps the two heroes equal-height
    // without clamping either to a fixed value (which overflowed).
    IntrinsicHeight(
      child: MatchmakerAttentionRow(stats: stats, onOpen: onOpen),
    ),
  ];
}

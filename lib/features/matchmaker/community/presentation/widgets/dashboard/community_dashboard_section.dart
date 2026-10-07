import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/dashboard/community_dashboard_cubit.dart';
import '../../screens/community_reports_page.dart';
import '../../screens/matchmaker_community_screen.dart';
import 'community_dashboard_actions.dart';
import 'community_dashboard_row.dart';

/// «المجتمع» on her Dashboard (A2–A4), after «تحتاج انتباهك»: new comments
/// on her posts → «منشوراتي», reports waiting → «البلاغات», live from her
/// badges; or, with no posts now, D35's line in their place. Then «المجتمع»
/// and «منشور جديد».
class CommunityDashboardSection extends StatelessWidget {
  const CommunityDashboardSection({super.key});

  static const _padding = EdgeInsets.fromLTRB(
    QeranSpacing.s16,
    QeranSpacing.s4,
    QeranSpacing.s16,
    QeranSpacing.s16,
  );

  @override
  Widget build(BuildContext context) {
    final hasPosts = context.watch<CommunityDashboardCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QeranSectionHeader(
          title: LocaleKeys.matchmaker_community_title.t(context),
          subtitle: LocaleKeys.matchmaker_dashboard_community_subtitle.t(
            context,
          ),
        ),
        QeranSpacing.vs12,
        _card(hasPosts),
      ],
    );
  }

  /// The rows — or, with no posts now, D35's line — then the two buttons.
  Widget _card(bool? hasPosts) => DecoratedBox(
    decoration: const BoxDecoration(
      color: QeranColors.paper,
      borderRadius: QeranRadii.cardR,
      boxShadow: QeranShadows.e2,
    ),
    child: Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPosts == false) const _NoPosts() else const _Rows(),
          QeranSpacing.vs8,
          const CommunityDashboardActions(),
        ],
      ),
    ),
  );
}

/// The two counts, from her badges as the hub keeps them.
class _Rows extends StatelessWidget {
  const _Rows();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgesCubit, BadgeCounts>(
      bloc: sl<BadgesCubit>(),
      builder: (context, counts) => Column(
        children: [_comments(context, counts), _reports(context, counts)],
      ),
    );
  }

  /// New comments on her posts → «منشوراتي» (which marks them seen, D33).
  Widget _comments(BuildContext context, BadgeCounts counts) =>
      CommunityDashboardRow(
        icon: Icons.mode_comment_outlined,
        label: LocaleKeys.matchmaker_dashboard_community_comments.t(context),
        count: counts.communityComments,
        divided: true,
        onTap: () => unawaited(
          openMatchmakerCommunity(context, tab: MatchmakerCommunityTab.mine),
        ),
      );

  /// Reports waiting → «البلاغات».
  Widget _reports(BuildContext context, BadgeCounts counts) =>
      CommunityDashboardRow(
        icon: Icons.outlined_flag_rounded,
        activeIcon: Icons.flag_rounded,
        gold: true,
        label: LocaleKeys.matchmaker_dashboard_community_reports.t(context),
        count: counts.communityReports,
        onTap: () => unawaited(openCommunityReports(context)),
      );
}

/// No posts now (A4, D35): read so it reads right after she deleted them all.
class _NoPosts extends StatelessWidget {
  const _NoPosts();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          const _FeedDisc(),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              LocaleKeys.matchmaker_dashboard_community_no_posts.t(context),
              style: QeranTypography.label.copyWith(
                color: QeranColors.inkBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedDisc extends StatelessWidget {
  const _FeedDisc();

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: QeranColors.softFill,
      borderRadius: QeranRadii.controlR,
    ),
    child: const Icon(
      Icons.dynamic_feed_rounded,
      size: 20,
      color: QeranColors.wine,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/entities/community_flagged_item.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/widgets/paginated_list.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/reports/community_reports_cubit.dart';
import 'report_card.dart';

/// «البلاغات»'s body (E7–E10): loading, none waiting, the error with its
/// retry, or the intro and a card per report, a page at a time.
class ReportsBody extends StatelessWidget {
  const ReportsBody({super.key, required this.onOpen, required this.onDelete});

  final void Function(CommunityFlaggedItem item) onOpen;
  final void Function(CommunityFlaggedItem item) onDelete;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CommunityReportsCubit>().state;
    final cubit = context.read<CommunityReportsCubit>();
    return switch (state.status) {
      CommunityReportsStatus.loading => const Center(child: QeranLoader()),
      CommunityReportsStatus.empty => _empty(context),
      CommunityReportsStatus.failure => QeranErrorState(
        icon: Icons.cloud_off_rounded,
        title: LocaleKeys.matchmaker_community_reports_error.t(context),
        retryLabel: LocaleKeys.community_her_retry.t(context),
        onRetry: cubit.load,
      ),
      CommunityReportsStatus.loaded => PaginatedList(
        onRefresh: cubit.reload,
        onLoadMore: cubit.loadMore,
        hasMore: state.hasMore,
        child: _list(context, state, cubit),
      ),
    };
  }

  /// None waiting (E9).
  Widget _empty(BuildContext context) => QeranEmptyState(
    icon: Icons.verified_user_outlined,
    title: LocaleKeys.matchmaker_community_reports_empty_title.t(context),
    message: LocaleKeys.matchmaker_community_reports_empty_body.t(context),
  );

  Widget _list(
    BuildContext context,
    CommunityReportsState state,
    CommunityReportsCubit cubit,
  ) => ListView(
    padding: const EdgeInsets.fromLTRB(
      QeranSpacing.s16,
      QeranSpacing.s12,
      QeranSpacing.s16,
      QeranSpacing.s24,
    ),
    children: [
      const _Intro(),
      for (final item in state.items)
        Padding(
          key: ValueKey('report-${item.flag.id}'),
          padding: const EdgeInsets.only(top: QeranSpacing.s12),
          child: ReportCard(
            item: item,
            answering: state.answering.contains(item.flag.id),
            onOpen: () => onOpen(item),
            onKeep: () => cubit.keep(item),
            onDelete: () => onDelete(item),
          ),
        ),
      if (state.loadingMore) const LoadMoreFooter(),
    ],
  );
}

/// «بلاغات على تعليقات وردود في منشوراتك…» over the cards.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s4),
    child: Text(
      LocaleKeys.matchmaker_community_reports_intro.t(context),
      style: QeranTypography.label.copyWith(
        color: QeranColors.inkMuted,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

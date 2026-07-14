import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/affiliate_commission.dart';
import '../../domain/entities/affiliate_summary.dart';
import '../blocs/affiliate_commissions_cubit.dart';
import '../blocs/affiliate_summary_cubit.dart';
import '../blocs/affiliate_summary_state.dart';
import '../widgets/affiliate_commission_row.dart';
import '../widgets/affiliate_dashboard_header.dart';
import '../widgets/affiliate_dashboard_states.dart';

/// Matchmaker affiliate & commissions dashboard (pushed from the account
/// screen). Caller is resolved from the JWT — no arguments. Wires two cubits:
/// [AffiliateSummaryCubit] (header: shared code + earnings tiles) and the
/// paginated [AffiliateCommissionsCubit] (the ledger below it).
///
/// Every resolved summary status maps to a concrete surface — loading, the
/// calm not-enrolled state (backend 404), the retryable error state, or the
/// loaded dashboard. No path shows an indefinite loader for a resolved state.
class MatchmakerAffiliateScreen extends StatelessWidget {
  const MatchmakerAffiliateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AffiliateSummaryCubit>()..load()),
        BlocProvider(
          create: (_) => sl<AffiliateCommissionsCubit>()..loadFirst(),
        ),
      ],
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.matchmaker_affiliate_row_title.t(context),
        ),
        body: const SafeArea(top: false, child: _AffiliateBody()),
      ),
    );
  }
}

class _AffiliateBody extends StatelessWidget {
  const _AffiliateBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AffiliateSummaryCubit, AffiliateSummaryState>(
      builder: (context, state) {
        final cubit = context.read<AffiliateSummaryCubit>();
        final summary = state.summary;
        switch (state.status) {
          case AffiliateSummaryStatus.notEnrolled:
            return AffiliateRefreshableCentered(
              onRefresh: cubit.load,
              child: QeranEmptyState(
                icon: Icons.workspace_premium_outlined,
                title:
                    LocaleKeys.matchmaker_affiliate_not_enrolled_title.t(context),
                message: LocaleKeys.matchmaker_affiliate_not_enrolled_message
                    .t(context),
              ),
            );
          case AffiliateSummaryStatus.error:
            return AffiliateRefreshableCentered(
              onRefresh: cubit.load,
              child: QeranErrorState(
                title: LocaleKeys.matchmaker_affiliate_error_title.t(context),
                message: (state.errorKey ?? LocaleKeys.errors_generic).t(context),
                retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
                onRetry: cubit.load,
              ),
            );
          case AffiliateSummaryStatus.loaded when summary != null:
            return _LoadedDashboard(summary: summary);
          case AffiliateSummaryStatus.initial:
          case AffiliateSummaryStatus.loading:
          case AffiliateSummaryStatus.loaded:
            return const Center(child: QeranLoader());
        }
      },
    );
  }
}

class _LoadedDashboard extends StatelessWidget {
  const _LoadedDashboard({required this.summary});

  final AffiliateSummary summary;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AffiliateCommissionsCubit,
        PaginatedListState<AffiliateCommission>>(
      builder: (context, ledger) {
        final commissions = context.read<AffiliateCommissionsCubit>();
        final summaryCubit = context.read<AffiliateSummaryCubit>();
        final hasRows = ledger.items.isNotEmpty;
        return MatchmakerPaginatedList(
          hasMore: hasRows && ledger.hasMore,
          onRefresh: () async {
            await summaryCubit.load();
            await commissions.refresh();
          },
          onLoadMore: commissions.loadMore,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s16,
              QeranSpacing.s16,
              QeranSpacing.s16,
              QeranSpacing.s24,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: 1 +
                (hasRows
                    ? ledger.items.length + (ledger.isLoadingMore ? 1 : 0)
                    : 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AffiliateDashboardHeader(summary: summary);
              }
              if (!hasRows) {
                return SizedBox(
                  height: 320,
                  child: AffiliateLedgerPlaceholder(
                    state: ledger,
                    cubit: commissions,
                  ),
                );
              }
              final rowIndex = index - 1;
              if (rowIndex >= ledger.items.length) {
                return const MatchmakerLoadMoreFooter();
              }
              return Column(
                children: [
                  AffiliateCommissionRow(
                    commission: ledger.items[rowIndex],
                    currency: ledger.items[rowIndex].currency,
                  ),
                  if (rowIndex < ledger.items.length - 1)
                    const Divider(height: 1, color: QeranColors.divider),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

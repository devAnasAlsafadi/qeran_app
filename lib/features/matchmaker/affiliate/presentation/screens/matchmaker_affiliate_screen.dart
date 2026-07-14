import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
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

/// Matchmaker affiliate & commissions dashboard (pushed from the account
/// screen). Caller is resolved from the JWT — no arguments. Wires two cubits:
/// [AffiliateSummaryCubit] (header: shared code + earnings tiles) and the
/// paginated [AffiliateCommissionsCubit] (the ledger below it).
///
/// This sub-step builds the LOADED state; the not-enrolled / error / empty /
/// refresh states are refined next — for now anything other than a loaded
/// summary shows a plain loader placeholder.
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
        body: SafeArea(top: false, child: const _AffiliateBody()),
      ),
    );
  }
}

class _AffiliateBody extends StatelessWidget {
  const _AffiliateBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AffiliateSummaryCubit, AffiliateSummaryState>(
      builder: (context, summaryState) {
        // Not-enrolled / error / loading states land in the next sub-step; for
        // now only a loaded summary renders the real dashboard.
        final summary = summaryState.summary;
        if (summaryState.status != AffiliateSummaryStatus.loaded ||
            summary == null) {
          return const Center(child: QeranLoader());
        }
        return _LoadedDashboard(summary: summary);
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
        return MatchmakerPaginatedList(
          hasMore: ledger.hasMore,
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
                ledger.items.length +
                (ledger.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AffiliateDashboardHeader(summary: summary);
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

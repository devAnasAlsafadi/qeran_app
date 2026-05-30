import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/compatibility_case.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import '../widgets/matchmaker_case_card.dart';
import '../widgets/matchmaker_cases_list_skeleton.dart';

/// Matchmaker compatibility-cases tab (M3a) — a single paginated, read-only
/// list of active cases. Cards are tappable but lead nowhere yet; the case
/// detail + server-validated status-update flow land in 3b.
class MatchmakerCasesTab extends StatelessWidget {
  const MatchmakerCasesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_cases.t(context),
      ),
      body: SafeArea(
        top: false,
        child: BlocProvider<MatchmakerCasesListCubit>(
          create: (_) => sl<MatchmakerCasesListCubit>()..loadFirst(),
          child: const _CasesListBody(),
        ),
      ),
    );
  }
}

class _CasesListBody extends StatelessWidget {
  const _CasesListBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerCasesListCubit,
        PaginatedListState<CompatibilityCase>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerCasesListCubit>();

        if (state.isLoading && state.items.isEmpty) {
          return const MatchmakerCasesListSkeleton();
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_cases_error_title.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_cases_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyRefreshable(onRefresh: cubit.refresh);
        }
        return MatchmakerPaginatedList(
          hasMore: state.hasMore,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s8,
              QeranSpacing.s20,
              QeranSpacing.s20,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const MatchmakerLoadMoreFooter();
              }
              return MatchmakerCaseCard(
                caseItem: state.items[index],
                onTap: () {
                  // Detail + status-update actions land in 3b.
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Empty state that still scrolls, so pull-to-refresh works on an empty
/// list.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return MatchmakerPaginatedList(
      hasMore: false,
      onRefresh: onRefresh,
      onLoadMore: () async {},
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: QeranEmptyState(
              icon: Icons.handshake_outlined,
              title: LocaleKeys.matchmaker_empty_cases_title.t(context),
              message: LocaleKeys.matchmaker_empty_cases_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}

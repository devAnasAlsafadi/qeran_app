import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_explore_user.dart';
import '../blocs/matchmaker_explore_cubit.dart';
import 'matchmaker_explore_card.dart';

/// The explore results body: loader / error / no-results / paginated list of
/// [MatchmakerExploreCard]s. Reads the [MatchmakerExploreCubit] from context;
/// a card tap opens the existing full profile (works for any user).
class MatchmakerExploreList extends StatelessWidget {
  const MatchmakerExploreList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerExploreCubit,
        PaginatedListState<MatchmakerExploreUser>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerExploreCubit>();

        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: QeranLoader());
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_explore_error_title.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_explore_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyResults(onRefresh: cubit.refresh);
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
              final user = state.items[index];
              return MatchmakerExploreCard(
                user: user,
                onTap: () => NavigationManager.navigateTo(
                  context,
                  RouteNames.matchmakerUserProfile,
                  arguments: user.userId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// No-results empty state that still scrolls, so pull-to-refresh works.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onRefresh});

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
              icon: Icons.travel_explore_outlined,
              title: LocaleKeys.matchmaker_explore_no_results_title.t(context),
              message:
                  LocaleKeys.matchmaker_explore_no_results_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}

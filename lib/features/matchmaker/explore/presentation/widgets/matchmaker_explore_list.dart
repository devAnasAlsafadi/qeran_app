import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../colleagues/presentation/blocs/matchmaker_colleague_open_chat_cubit.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../../users/presentation/widgets/matchmaker_notes_sheet.dart';
import '../../domain/entities/matchmaker_explore_user.dart';
import '../blocs/matchmaker_explore_cubit.dart';
import 'matchmaker_explore_card.dart';
import 'matchmaker_share_sheet.dart';

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
        // The matchmaker whose chat is resolving on tap — drives the chip loader.
        final colleagueOpeningId =
            context.watch<MatchmakerColleagueOpenChatCubit>().state.openingUserId;

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
            padding: EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s8,
              QeranSpacing.s20,
              QeranBottomNav.contentClearance(context),
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
                onView: () => NavigationManager.navigateTo(
                  context,
                  RouteNames.matchmakerUserProfile,
                  arguments: user.userId,
                ),
                // Share is independent of assignment — available on every card.
                onShare: () =>
                    showMatchmakerShareSheet(context, sharedUserId: user.userId),
                // Notes are assigned-only (the endpoint returns UNAUTHORIZED
                // otherwise) — hidden for users assigned to another matchmaker.
                onNotes: user.isMyAssigned
                    ? () => showMatchmakerNotesSheet(context, userId: user.userId)
                    : null,
                // Matchmaker chat — only when the user has a DIFFERENT
                // matchmaker (mutually exclusive with Notes).
                onMessageMatchmaker: (!user.isMyAssigned &&
                        (user.assignedMatchmakerId?.isNotEmpty ?? false))
                    ? () => _messageMatchmaker(context, user)
                    : null,
                matchmakerLoading:
                    colleagueOpeningId == user.assignedMatchmakerId,
              );
            },
          ),
        );
      },
    );
  }

  /// Resolve-or-create the chat with [user]'s matchmaker via the shared
  /// colleague open-chat flow (host handles nav / the calm notice). The peer
  /// identity is echoed from the row; the image is null until the backend
  /// populates `assignedMatchmakerImageUrl` (then it flows through unchanged).
  void _messageMatchmaker(BuildContext context, MatchmakerExploreUser user) {
    context.read<MatchmakerColleagueOpenChatCubit>().open(
          colleagueId: user.assignedMatchmakerId ?? '',
          fullName: user.assignedMatchmakerName ?? '',
          profileImageUrl: user.assignedMatchmakerImageUrl,
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

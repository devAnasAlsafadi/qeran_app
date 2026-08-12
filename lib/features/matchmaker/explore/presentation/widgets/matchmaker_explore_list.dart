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
import '../../../users/presentation/matchmaker_user_profile_args.dart';
import '../../domain/entities/matchmaker_explore_user.dart';
import '../blocs/matchmaker_explore_cubit.dart';
import 'matchmaker_explore_card.dart';
import 'matchmaker_share_sheet.dart';

/// The explore results body: loader / error / no-results / paginated list of
/// [MatchmakerExploreCard]s. Reads the [MatchmakerExploreCubit] from context;
/// a card tap opens the existing full profile (works for any user).
class MatchmakerExploreList extends StatefulWidget {
  const MatchmakerExploreList({super.key});

  @override
  State<MatchmakerExploreList> createState() => _MatchmakerExploreListState();
}

class _MatchmakerExploreListState extends State<MatchmakerExploreList> {
  /// The candidate card whose matchmaker-chat is currently resolving. Keyed on
  /// the candidate's own userId (unique per card), NOT the owning matchmaker id
  /// — several candidates can share one matchmaker, so keying on the owner made
  /// every one of their cards spin when only one was tapped.
  String? _openingCandidateId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      MatchmakerExploreCubit,
      PaginatedListState<MatchmakerExploreUser>
    >(
      builder: (context, state) {
        final cubit = context.read<MatchmakerExploreCubit>();
        // Whether a colleague chat is currently resolving (the host owns the
        // single-in-flight guard); combined with [_openingCandidateId] so only
        // the tapped card shows its loader.
        final resolving = context
            .watch<MatchmakerColleagueOpenChatCubit>()
            .state
            .isOpening;

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
                  arguments: MatchmakerUserProfileArgs(
                    userId: user.userId,
                    responsibleMatchmaker:
                        !user.isMyAssigned &&
                            (user.assignedMatchmakerId?.isNotEmpty ?? false)
                        ? ResponsibleMatchmakerContact(
                            id: user.assignedMatchmakerId!,
                            name: user.assignedMatchmakerName ?? '',
                            profileImageUrl: user.assignedMatchmakerImageUrl,
                          )
                        : null,
                  ),
                ),
                // Share is independent of assignment — available on every card.
                onShare: () => showMatchmakerShareSheet(
                  context,
                  sharedUserId: user.userId,
                  candidateName: user.fullName,
                  candidateAge: user.age,
                  candidateImageUrl: user.profileImageUrl,
                ),
                // Notes are assigned-only (the endpoint returns UNAUTHORIZED
                // otherwise) — hidden for users assigned to another matchmaker.
                onNotes: user.isMyAssigned
                    ? () =>
                          showMatchmakerNotesSheet(context, userId: user.userId)
                    : null,
                // Matchmaker chat — only when the user has a DIFFERENT
                // matchmaker (mutually exclusive with Notes).
                onMessageMatchmaker:
                    (!user.isMyAssigned &&
                        (user.assignedMatchmakerId?.isNotEmpty ?? false))
                    ? () => _messageMatchmaker(context, user)
                    : null,
                matchmakerLoading:
                    resolving && _openingCandidateId == user.userId,
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
    // Mark THIS card as the one resolving so only its disc shows the loader.
    setState(() => _openingCandidateId = user.userId);
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
              icon: Icons.person_search_outlined,
              title: LocaleKeys.matchmaker_explore_no_results_title.t(context),
              message: LocaleKeys.matchmaker_explore_no_results_message.t(
                context,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

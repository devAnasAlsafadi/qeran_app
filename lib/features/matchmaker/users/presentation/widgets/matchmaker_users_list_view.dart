import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../conversations/presentation/blocs/matchmaker_open_chat_cubit.dart';
import '../../../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../../../conversations/presentation/widgets/matchmaker_open_chat_host.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_user_row.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../blocs/matchmaker_users_list_cubit.dart';
import 'matchmaker_plan_filter_listener.dart';
import 'matchmaker_notes_sheet.dart';
import 'matchmaker_user_row_card.dart';
import 'matchmaker_users_empty_refreshable.dart';
import 'matchmaker_users_list_skeleton.dart';

/// One user list: owns its own [MatchmakerUsersListCubit] and renders the
/// loading / error / empty / populated states. Kept alive by the parent
/// IndexedStack so pagination + scroll survive sub-tab switches.
class MatchmakerUsersListView extends StatelessWidget {
  const MatchmakerUsersListView({
    super.key,
    required this.list,
    this.planFiltered = false,
    this.showPlanChip = true,
  });

  final MatchmakerUsersList list;

  /// When true (subscribed list only), the view listens to an ancestor
  /// [SubscriptionPlansCubit] and re-fetches with the selected `planId`.
  final bool planFiltered;

  /// Whether subscribed cards render their plan chip — false when the rail has
  /// filtered to one plan (redundant). Defaulted true for the other lists.
  final bool showPlanChip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerUsersListCubit>(
      create: (_) => sl<MatchmakerUsersListCubit>(param1: list)..loadFirst(),
      // The host provides the open-chat cubit + navigates/snackbars on its
      // outcome; descendant cards drive it via onMessage (M3c).
      child: MatchmakerOpenChatHost(
        child: planFiltered
            ? MatchmakerPlanFilterListener(
                child: _ListBody(list: list, showPlanChip: showPlanChip),
              )
            : _ListBody(list: list, showPlanChip: showPlanChip),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.list, this.showPlanChip = true});

  final MatchmakerUsersList list;
  final bool showPlanChip;

  /// A row left the list (approved or rejected). Refresh the list AND the
  /// dashboard stats.
  ///
  /// The "بالانتظار" badge is fed by the dashboard's `pendingUsersCount`, not
  /// by this list, so refreshing only the list left the old number sitting
  /// over an empty list. Refetching the count on the very action that removed
  /// the row keeps the two in step without the client ever guessing at a
  /// decrement.
  void _onRowMutated(
    BuildContext context,
    MatchmakerUsersListCubit cubit,
  ) {
    cubit.refresh();
    context.read<MatchmakerDashboardCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerUsersListCubit,
        PaginatedListState<MatchmakerUserRow>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerUsersListCubit>();
        // Drives the inline loader on the tapped card's مراسلة button while its
        // conversation resolves (M3c).
        final openingUserId =
            context.watch<MatchmakerOpenChatCubit>().state.openingUserId;

        // Fade-through between phases (skeleton → empty/error → list) so a
        // plan-filter change cross-fades instead of snapping. Gentle fade
        // only, at the app's content-swap tempo; each phase carries a stable
        // key so the switcher knows when to animate. Pagination load-more
        // doesn't change the key, so appended pages don't re-fade.
        return AnimatedSwitcher(
          duration: QeranMotion.standard,
          switchInCurve: QeranCurves.standard,
          switchOutCurve: QeranCurves.standard,
          child: _phase(context, state, cubit, openingUserId),
        );
      },
    );
  }

  Widget _phase(
    BuildContext context,
    PaginatedListState<MatchmakerUserRow> state,
    MatchmakerUsersListCubit cubit,
    String? openingUserId,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const MatchmakerUsersListSkeleton(key: ValueKey('skeleton'));
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return QeranErrorState(
        key: const ValueKey('error'),
        title: LocaleKeys.matchmaker_users_error_title.t(context),
        message: state.errorMessage!.t(context),
        retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
        onRetry: cubit.loadFirst,
      );
    }
    if (state.items.isEmpty) {
      return MatchmakerUsersEmptyRefreshable(
        key: const ValueKey('empty'),
        onRefresh: cubit.refresh,
        title: _emptyTitleKey(list).t(context),
        message: LocaleKeys.matchmaker_users_empty_message.t(context),
      );
    }
    return MatchmakerPaginatedList(
      key: const ValueKey('list'),
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
              final row = state.items[index];
              // Card body isn't tappable; actions live on the card's buttons.
              // onMutated re-runs the list fetch after approve/reject; onMessage
              // opens the chat (M3c); onNotes the notes sheet (M3d); onView the
              // view-only profile (M3e).
              return MatchmakerUserRowCard(
                row: row,
                list: list,
                showPlanChip: showPlanChip,
                onMutated: () => _onRowMutated(context, cubit),
                onMessage: () =>
                    context.read<MatchmakerOpenChatCubit>().open(
                          userId: row.userId,
                          fullName: row.fullName,
                          profileImageUrl: row.profileImageUrl,
                        ),
                onNotes: () =>
                    showMatchmakerNotesSheet(context, userId: row.userId),
                onView: () => NavigationManager.navigateTo(
                  context,
                  RouteNames.matchmakerUserProfile,
                  arguments: row.userId,
                ),
                // الإهتمامات — only the subscribed list shows this button, so
                // the action only ever fires there (M3f).
                onInterests: () => NavigationManager.navigateTo(
                  context,
                  RouteNames.matchmakerInterests,
                  arguments: row.userId,
                ),
                loadingAction: openingUserId == row.userId
                    ? MatchmakerCardAction.message
                    : null,
              );
            },
      ),
    );
  }

  String _emptyTitleKey(MatchmakerUsersList list) => switch (list) {
        MatchmakerUsersList.pending =>
          LocaleKeys.matchmaker_users_empty_pending_title,
        MatchmakerUsersList.approvedUnsubscribed =>
          LocaleKeys.matchmaker_users_empty_unsubscribed_title,
        MatchmakerUsersList.approvedSubscribed =>
          LocaleKeys.matchmaker_users_empty_subscribed_title,
      };
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_user_row.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../blocs/matchmaker_users_list_cubit.dart';
import 'matchmaker_user_row_card.dart';
import 'matchmaker_users_list_skeleton.dart';

/// One user list: owns its own [MatchmakerUsersListCubit] and renders the
/// loading / error / empty / populated states. Kept alive by the parent
/// IndexedStack so pagination + scroll survive sub-tab switches.
class MatchmakerUsersListView extends StatelessWidget {
  const MatchmakerUsersListView({super.key, required this.list});

  final MatchmakerUsersList list;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerUsersListCubit>(
      create: (_) =>
          sl<MatchmakerUsersListCubit>(param1: list)..loadFirst(),
      child: _ListBody(list: list),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.list});

  final MatchmakerUsersList list;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerUsersListCubit,
        PaginatedListState<MatchmakerUserRow>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerUsersListCubit>();

        if (state.isLoading && state.items.isEmpty) {
          return const MatchmakerUsersListSkeleton();
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_users_error_title.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyRefreshable(
            onRefresh: cubit.refresh,
            title: _emptyTitleKey(list).t(context),
            message: LocaleKeys.matchmaker_users_empty_message.t(context),
          );
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
              final row = state.items[index];
              return MatchmakerUserRowCard(
                row: row,
                onTap: () => NavigationManager.navigateTo(
                  context,
                  RouteNames.matchmakerUserProfile,
                  arguments: row.userId,
                ),
              );
            },
          ),
        );
      },
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

/// Empty state that still scrolls, so pull-to-refresh works on an empty
/// list.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({
    required this.onRefresh,
    required this.title,
    required this.message,
  });

  final Future<void> Function() onRefresh;
  final String title;
  final String message;

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
              icon: Icons.people_outline_rounded,
              title: title,
              message: message,
            ),
          ),
        ),
      ),
    );
  }
}

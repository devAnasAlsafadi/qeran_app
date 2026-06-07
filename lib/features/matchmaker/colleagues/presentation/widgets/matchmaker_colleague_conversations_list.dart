import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../conversations/presentation/widgets/matchmaker_conversation_card.dart';
import '../../../conversations/presentation/widgets/matchmaker_conversations_list_skeleton.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../blocs/matchmaker_colleague_conversations_cubit.dart';

/// The Colleagues segment of the conversations tab: owns its
/// [MatchmakerColleagueConversationsCubit] and renders loading / error / empty
/// / populated states. A clone of `MatchmakerUserConversationsList` reusing the
/// conversation card + skeleton (the row entity is the generic
/// [MatchmakerConversation]). Kept alive by the tab's IndexedStack.
class MatchmakerColleagueConversationsList extends StatelessWidget {
  const MatchmakerColleagueConversationsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerColleagueConversationsCubit>(
      create: (ctx) =>
          sl<MatchmakerColleagueConversationsCubit>(param1: _readMyId(ctx))
            ..loadFirst(),
      child: const _ListBody(),
    );
  }

  /// Current user's id from the session — passed to the cubit so its live
  /// `ReceiveMessage` handling can tell self-sent from inbound. Empty when
  /// unauthenticated (e.g. test scope).
  static String _readMyId(BuildContext context) {
    try {
      final s = context.read<UserSessionCubit>().state;
      if (s is UserSessionAuthenticated) return s.user.id;
    } catch (_) {
      // No session in test scope.
    }
    return '';
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerColleagueConversationsCubit,
        PaginatedListState<MatchmakerConversation>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerColleagueConversationsCubit>();

        if (state.isLoading && state.items.isEmpty) {
          return const MatchmakerConversationsListSkeleton();
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_conversations_error_title.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_conversations_retry.t(context),
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
              final conversation = state.items[index];
              return MatchmakerConversationCard(
                conversation: conversation,
                onTap: () async {
                  await NavigationManager.navigateTo(
                    context,
                    RouteNames.matchmakerUserChat,
                    arguments: conversation,
                  );
                  if (context.mounted) {
                    context
                        .read<MatchmakerColleagueConversationsCubit>()
                        .refresh();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Empty state that still scrolls, so pull-to-refresh works on an empty list.
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
              icon: Icons.groups_2_outlined,
              title: LocaleKeys
                  .matchmaker_conversations_colleagues_empty_title
                  .t(context),
              message: LocaleKeys
                  .matchmaker_conversations_colleagues_empty_message
                  .t(context),
            ),
          ),
        ),
      ),
    );
  }
}

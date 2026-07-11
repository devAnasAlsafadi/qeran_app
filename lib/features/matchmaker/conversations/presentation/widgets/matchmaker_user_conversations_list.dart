import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_conversation.dart';
import '../blocs/matchmaker_user_conversations_cubit.dart';
import 'matchmaker_conversation_card.dart';
import 'matchmaker_conversations_list_skeleton.dart';

/// The Users segment of the conversations tab: owns its
/// [MatchmakerUserConversationsCubit] and renders the loading / error / empty
/// / populated states. Kept alive by the tab's IndexedStack so pagination +
/// scroll survive segment switches.
class MatchmakerUserConversationsList extends StatelessWidget {
  const MatchmakerUserConversationsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerUserConversationsCubit>(
      create: (ctx) =>
          sl<MatchmakerUserConversationsCubit>(param1: _readMyId(ctx))
            ..loadFirst(),
      child: const _ListBody(),
    );
  }

  /// Current user's id from the session — passed to the cubit so its live
  /// `ReceiveMessage` handling can tell self-sent from inbound. Empty when
  /// unauthenticated (e.g. test scope); mirrors the chat screen's reader.
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
    return BlocBuilder<MatchmakerUserConversationsCubit,
        PaginatedListState<MatchmakerConversation>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerUserConversationsCubit>();

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
              final conversation = state.items[index];
              return MatchmakerConversationCard(
                conversation: conversation,
                onTap: () async {
                  await NavigationManager.navigateTo(
                    context,
                    RouteNames.matchmakerUserChat,
                    arguments: conversation,
                  );
                  // The chat auto-marked the conversation read on open. Clear
                  // just this row's badge locally — NOT a full list re-fetch
                  // (that flashed the whole inbox on every open). Other rows
                  // stay live via the realtime `ReceiveMessage` handler.
                  if (context.mounted) {
                    context
                        .read<MatchmakerUserConversationsCubit>()
                        .markConversationRead(conversation.conversationId);
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
              icon: Icons.chat_bubble_outline_rounded,
              title: LocaleKeys.matchmaker_conversations_empty_title.t(context),
              message:
                  LocaleKeys.matchmaker_conversations_empty_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}

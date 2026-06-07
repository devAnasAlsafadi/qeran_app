import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
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
import '../../../conversations/presentation/widgets/matchmaker_conversations_list_skeleton.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_colleague.dart';
import '../blocs/matchmaker_colleague_open_chat_cubit.dart';
import '../blocs/matchmaker_colleagues_directory_cubit.dart';
import '../widgets/matchmaker_colleague_card.dart';
import '../widgets/matchmaker_colleague_open_chat_host.dart';

/// The colleague directory — the roster a matchmaker browses to START a chat
/// with another matchmaker. Pushed as its own route from the colleagues
/// segment's "new conversation" affordance. Tapping a row opens the existing
/// chat directly when a conversation already exists, otherwise resolves one via
/// the open-chat host before navigating.
class MatchmakerColleaguesDirectoryScreen extends StatelessWidget {
  const MatchmakerColleaguesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_conversations_colleagues_directory_title
            .t(context),
      ),
      body: SafeArea(
        top: false,
        child: MatchmakerColleagueOpenChatHost(
          child: BlocProvider<MatchmakerColleaguesDirectoryCubit>(
            create: (_) =>
                sl<MatchmakerColleaguesDirectoryCubit>()..loadFirst(),
            child: const _DirectoryBody(),
          ),
        ),
      ),
    );
  }
}

class _DirectoryBody extends StatelessWidget {
  const _DirectoryBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerColleaguesDirectoryCubit,
        PaginatedListState<MatchmakerColleague>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerColleaguesDirectoryCubit>();
        final openingId = context
            .watch<MatchmakerColleagueOpenChatCubit>()
            .state
            .openingUserId;

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
              final colleague = state.items[index];
              return MatchmakerColleagueCard(
                colleague: colleague,
                isResolving: openingId == colleague.matchmakerId,
                onTap: () => _onTap(context, colleague),
              );
            },
          ),
        );
      },
    );
  }

  /// Already has a thread → open the chat directly (no needless round-trip).
  /// Otherwise resolve the conversation via the open-chat cubit; the host
  /// navigates on the `ready` outcome.
  void _onTap(BuildContext context, MatchmakerColleague colleague) {
    final existing = colleague.conversationId;
    if (existing != null) {
      NavigationManager.navigateTo(
        context,
        RouteNames.matchmakerUserChat,
        arguments: MatchmakerConversation(
          userId: colleague.matchmakerId,
          fullName: colleague.name,
          profileImageUrl: colleague.profileImageUrl,
          conversationId: existing,
          lastMessageAt: null,
          lastMessagePreview: null,
          unreadCount: 0,
        ),
      );
      return;
    }
    context.read<MatchmakerColleagueOpenChatCubit>().open(
          colleagueId: colleague.matchmakerId,
          fullName: colleague.name,
          profileImageUrl: colleague.profileImageUrl,
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
              icon: Icons.group_add_outlined,
              title: LocaleKeys
                  .matchmaker_conversations_colleagues_directory_empty_title
                  .t(context),
              message: LocaleKeys
                  .matchmaker_conversations_colleagues_directory_empty_message
                  .t(context),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
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
      create: (_) => sl<MatchmakerUserConversationsCubit>()..loadFirst(),
      child: const _ListBody(),
    );
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
              return MatchmakerConversationCard(
                conversation: state.items[index],
                onTap: () {
                  // Opening the chat screen is 4b.
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

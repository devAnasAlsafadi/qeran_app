import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../colleagues/presentation/blocs/matchmaker_colleague_open_chat_cubit.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../conversations/presentation/blocs/matchmaker_open_chat_cubit.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/compatibility_case.dart';
import '../blocs/matchmaker_cases_filter_cubit.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import 'matchmaker_case_card.dart';

/// Hidden until the backend returns a conversationId from
/// POST /colleagues/{id}/open-chat (it currently 200s with none, so the chat
/// can't resolve). Wiring stays intact — flip to true to restore the button.
const bool _matchmakerButtonEnabled = false;

/// The populated cases list — renders the [visible] (already filtered) items
/// over the underlying paginated [state]. Pagination still operates on the full
/// loaded set; the footer shows while more pages exist.
class MatchmakerCasesListView extends StatelessWidget {
  const MatchmakerCasesListView({
    super.key,
    required this.state,
    required this.visible,
  });

  final PaginatedListState<CompatibilityCase> state;
  final List<CompatibilityCase> visible;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerCasesListCubit>();
    // The peer whose chat is resolving (early tap) — drives the chip loader.
    final openingUserId =
        context.watch<MatchmakerOpenChatCubit>().state.openingUserId;
    final colleagueOpeningId =
        context.watch<MatchmakerColleagueOpenChatCubit>().state.openingUserId;
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
        itemCount: visible.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return const MatchmakerLoadMoreFooter();
          }
          final caseItem = visible[index];
          final chat = caseItem.chat;
          return MatchmakerCaseCard(
            caseItem: caseItem,
            onTap: () async {
              final changed = await NavigationManager.navigateTo(
                context,
                RouteNames.matchmakerCaseDetail,
                arguments: caseItem,
              );
              if (changed == true && context.mounted) {
                context.read<MatchmakerCasesListCubit>().refresh();
              }
            },
            // Matchmaker button temporarily disabled — see [_matchmakerButtonEnabled].
            onMessageMatchmaker: (!_matchmakerButtonEnabled ||
                    (chat.otherMatchmakerId?.isEmpty ?? true))
                ? null
                : () => _messageMatchmaker(context, caseItem),
            matchmakerLoading: colleagueOpeningId == chat.otherMatchmakerId,
            // Message the other person — available on EVERY case. Direct nav
            // when the conversation id is already populated (advanced cases);
            // otherwise resolve-or-create it on tap (early cases).
            onMessagePerson: caseItem.otherUser.userId.isEmpty
                ? null
                : () => _messagePerson(context, caseItem),
            personLoading: openingUserId == caseItem.otherUser.userId,
            // Placeholder — notes UI not built yet.
            onNotes: () {},
          );
        },
      ),
    );
  }

  /// Opens the other-person chat — direct nav when it exists, else
  /// resolve-or-create by user id (host navigates / shows the calm notice).
  void _messagePerson(BuildContext context, CompatibilityCase caseItem) {
    final other = caseItem.otherUser;
    final existingId = caseItem.chat.otherUserConversationId;
    if (existingId != null) {
      _openChat(
        context,
        conversationId: existingId,
        peerId: other.userId,
        name: other.firstName,
        imageUrl: other.profileImageUrl,
      );
      return;
    }
    context.read<MatchmakerOpenChatCubit>().open(
          userId: other.userId,
          fullName: other.firstName,
          profileImageUrl: other.profileImageUrl,
        );
  }

  /// Opens the OTHER side's matchmaker chat via the colleague path — direct nav
  /// when it exists, else resolve-or-create by colleague id (host handles both).
  void _messageMatchmaker(BuildContext context, CompatibilityCase caseItem) {
    final chat = caseItem.chat;
    final id = chat.otherMatchmakerId ?? '';
    final existingId = chat.otherMatchmakerConversationId;
    if (existingId != null) {
      _openChat(context, conversationId: existingId, peerId: id, name: '');
      return;
    }
    context.read<MatchmakerColleagueOpenChatCubit>().open(
          colleagueId: id,
          fullName: '',
          profileImageUrl: null,
        );
  }

  /// Pushes the matchmaker chat for [conversationId] (loaded by id alone; the
  /// peer fields only label the header — empty for the matchmaker, by decision).
  void _openChat(
    BuildContext context, {
    required int conversationId,
    required String peerId,
    required String name,
    String? imageUrl,
  }) {
    NavigationManager.navigateTo(
      context,
      RouteNames.matchmakerUserChat,
      arguments: MatchmakerConversation(
        userId: peerId,
        fullName: name,
        profileImageUrl: imageUrl,
        conversationId: conversationId,
        lastMessageAt: null,
        lastMessagePreview: null,
        unreadCount: 0,
      ),
    );
  }
}

/// Shown when a filter is active but no loaded case matches it.
class MatchmakerCasesFilteredEmpty extends StatelessWidget {
  const MatchmakerCasesFilteredEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: QeranEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: LocaleKeys.matchmaker_cases_filter_empty_title.t(context),
            message:
                LocaleKeys.matchmaker_cases_filter_empty_message.t(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            0,
            QeranSpacing.s20,
            QeranSpacing.s20,
          ),
          child: QeranButton(
            label: LocaleKeys.matchmaker_cases_filter_clear.t(context),
            variant: QeranButtonVariant.ghost,
            onPressed: () =>
                context.read<MatchmakerCasesFilterCubit>().clear(),
          ),
        ),
      ],
    );
  }
}

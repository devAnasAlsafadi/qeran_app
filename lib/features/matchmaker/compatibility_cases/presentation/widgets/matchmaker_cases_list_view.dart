import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/api/end_points.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
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
import 'case_note_sheet.dart';
import 'matchmaker_case_card.dart';

/// Gates the "message the matchmaker" button. Re-enabled now that the backend
/// returns a usable conversationId from POST /colleagues/{id}/open-chat
/// (unified `{ data: { conversationId } }` shape). Gating below still hides it
/// per-case when `otherMatchmakerId` is null (no colleague to message).
const bool _matchmakerButtonEnabled = true;

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
        padding: EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s8,
          QeranSpacing.s20,
          QeranBottomNav.contentClearance(context),
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
            // Shown only when a colleague exists to message — see
            // [_matchmakerButtonEnabled] for the feature gate.
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
            onNotes: () => _openNotes(context, caseItem),
          );
        },
      ),
    );
  }

  /// Opens the private per-case note sheet and reflects the result on the
  /// card's note indicator in place — `true` → has note, `false` → removed,
  /// `null` (cancel / terminal failure) → no change. No list reload.
  Future<void> _openNotes(
    BuildContext context,
    CompatibilityCase caseItem,
  ) async {
    final cubit = context.read<MatchmakerCasesListCubit>();
    final result = await showCaseNoteSheet(context, caseId: caseItem.caseId);
    if (result == null) return;
    cubit.markNoteState(caseItem.caseId, result);
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
  /// Carries the real peer identity from the case so the header shows the
  /// matchmaker's name + avatar; name null → '' (the header's generic-label
  /// fallback), image null/empty → null (default avatar).
  void _messageMatchmaker(BuildContext context, CompatibilityCase caseItem) {
    final chat = caseItem.chat;
    final id = chat.otherMatchmakerId ?? '';
    final name = chat.otherMatchmakerName ?? '';
    final rawImage = chat.otherMatchmakerImageUrl;
    final imageUrl = (rawImage == null || rawImage.isEmpty)
        ? null
        : EndPoints.absoluteUrl(rawImage);
    final existingId = chat.otherMatchmakerConversationId;
    if (existingId != null) {
      _openChat(
        context,
        conversationId: existingId,
        peerId: id,
        name: name,
        imageUrl: imageUrl,
      );
      return;
    }
    context.read<MatchmakerColleagueOpenChatCubit>().open(
          colleagueId: id,
          fullName: name,
          profileImageUrl: imageUrl,
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

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
import '../../domain/entities/case_user.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/matchmaker_cases_filter.dart';
import '../blocs/matchmaker_cases_filter_cubit.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import '../screens/matchmaker_case_detail_screen.dart';
import 'case_note_sheet.dart';
import 'case_status_update_sheet.dart';
import 'matchmaker_case_card.dart';

/// Gates the "message the matchmaker" button. Re-enabled now that the backend
/// returns a usable conversationId from POST /colleagues/{id}/open-chat
/// (unified `{ data: { conversationId } }` shape). Gating below still hides it
/// per-case when `otherMatchmakerId` is null (no colleague to message).
const bool _matchmakerButtonEnabled = true;

/// The populated server-filtered cases page. [visible] preserves the exact
/// order returned by the backend; pagination continues the same query.
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
    final openingUserId = context
        .watch<MatchmakerOpenChatCubit>()
        .state
        .openingUserId;
    final colleagueOpeningId = context
        .watch<MatchmakerColleagueOpenChatCubit>()
        .state
        .openingUserId;
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
              // Direct push (not the named route) so the live cases-list cubit
              // stays in scope on the detail: it reads the case's CURRENT status
              // from the already-loaded, realtime-live list and builds the
              // actions from that — never the frozen tap-time snapshot. No extra
              // network fetch.
              final listCubit = context.read<MatchmakerCasesListCubit>();
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  settings: const RouteSettings(
                    name: RouteNames.matchmakerCaseDetail,
                  ),
                  builder: (_) => BlocProvider.value(
                    value: listCubit,
                    child: MatchmakerCaseDetailScreen(caseItem: caseItem),
                  ),
                ),
              );
              if (changed == true && context.mounted) {
                listCubit.refresh();
              }
            },
            // Shown only when a colleague exists to message — see
            // [_matchmakerButtonEnabled] for the feature gate.
            onMessageMatchmaker:
                (!_matchmakerButtonEnabled ||
                    !caseItem.canMessageOtherMatchmaker)
                ? null
                : () => _messageMatchmaker(context, caseItem),
            matchmakerLoading:
                caseItem.canMessageOtherMatchmaker &&
                colleagueOpeningId == chat.otherMatchmakerId,
            // Direct person chat is available only when the other participant
            // is assigned to this matchmaker.
            onMessagePerson: !caseItem.canMessageOtherUser
                ? null
                : () => _messagePerson(context, caseItem),
            personLoading:
                caseItem.canMessageOtherUser &&
                openingUserId == caseItem.otherUser.userId,
            // Both participants mine → the card also needs a chat for MY user;
            // with only the other-person chip there was no way to reach them.
            onMessageMyUser: !caseItem.canMessageMyUser
                ? null
                : () => _messageMyUser(context, caseItem),
            myUserLoading:
                caseItem.canMessageMyUser &&
                openingUserId == caseItem.myUser.userId,
            onNotes: () => _openNotes(context, caseItem),
            // Always wired — the sheet decides what is offerable and explains
            // the rest, rather than the button vanishing on terminal cases.
            onUpdateStatus: () =>
                showCaseStatusUpdateSheet(context, caseItem: caseItem),
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
  void _messagePerson(BuildContext context, CompatibilityCase caseItem) =>
      _messageParticipant(
        context,
        user: caseItem.otherUser,
        existingConversationId: caseItem.chat.otherUserConversationId,
      );

  /// Same path for the matchmaker's OWN participant, off `myUserConversationId`
  /// — the id was already modelled on `CaseChat` but nothing consumed it.
  void _messageMyUser(BuildContext context, CompatibilityCase caseItem) =>
      _messageParticipant(
        context,
        user: caseItem.myUser,
        existingConversationId: caseItem.chat.myUserConversationId,
      );

  void _messageParticipant(
    BuildContext context, {
    required CaseUser user,
    required int? existingConversationId,
  }) {
    if (existingConversationId != null) {
      _openChat(
        context,
        conversationId: existingConversationId,
        peerId: user.userId,
        name: user.name,
        imageUrl: user.profileImageUrl,
      );
      return;
    }
    context.read<MatchmakerOpenChatCubit>().open(
      userId: user.userId,
      fullName: user.name,
      profileImageUrl: user.profileImageUrl,
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
            message: LocaleKeys.matchmaker_cases_filter_empty_message.t(
              context,
            ),
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
            onPressed: () {
              const cleared = MatchmakerCasesFilter();
              context.read<MatchmakerCasesFilterCubit>().clear();
              context.read<MatchmakerCasesListCubit>().applyFilter(cleared);
            },
          ),
        ),
      ],
    );
  }
}

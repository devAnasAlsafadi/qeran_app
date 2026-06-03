import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_section_header.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/likes_tab.dart';
import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../widgets/likes_segmented_tabs.dart';
import 'likes_received_section.dart';
import 'likes_sent_section.dart';
import 'match_success_screen.dart';
import 'matches_section.dart';
import 'matchmaker_chat_screen.dart';

/// Likes / Interests screen — entry point from the bottom nav (index 1).
///
/// Three tabs: Sent (outgoing), Received (incoming), and Matches
/// (post-acceptance). Each tab loads lazily through [LikesCubit] and
/// renders one of four states: loading, empty, error, list.
class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LikesCubit>(
      create: (_) => sl<LikesCubit>()..primeActiveTab(),
      child: const _LikesView(),
    );
  }
}

class _LikesView extends StatelessWidget {
  const _LikesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<LikesCubit, LikesState>(
          // Listener only fires on `actionEventVersion` bumps so toasts
          // and the paywall sheet can never re-trigger from an
          // unrelated state change (tab switch, refresh, etc).
          listenWhen: (prev, curr) =>
              prev.actionEventVersion != curr.actionEventVersion &&
              curr.actionEvent != LikesActionEvent.none,
          listener: _onActionEvent,
          builder: (context, state) {
            return Column(
              children: [
                _Header(),
                LikesSegmentedTabs(
                  active: state.activeTab,
                  onChanged: context.read<LikesCubit>().switchTab,
                ),
                Expanded(child: _TabBody(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Dispatches the cubit's one-shot outcome to a snackbar / paywall.
  /// Backend messages are NEVER shown verbatim — every branch uses a
  /// localized key.
  void _onActionEvent(BuildContext context, LikesState state) {
    switch (state.actionEvent) {
      case LikesActionEvent.none:
        break;
      // Like accept / reject
      case LikesActionEvent.acceptSuccess:
        NavigationManager.navigateTo(
          context,
          RouteNames.matchSuccess,
          arguments: const MatchSuccessArgs(),
        );
      case LikesActionEvent.acceptRequiresSubscription:
        showPaywall(context, intent: PaywallIntent.acceptLike);
      case LikesActionEvent.acceptExpired:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_request_expired.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.acceptNotFound:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_request_not_found.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.acceptFailure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_failed.t(context),
          type: SnackBarType.error,
        );
      case LikesActionEvent.rejectSuccess:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_rejected_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.rejectExpired:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_request_expired.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.rejectNotFound:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_request_not_found.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.rejectFailure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_action_failed.t(context),
          type: SnackBarType.error,
        );
      // Photo-exchange request (initiator)
      case LikesActionEvent.photoExchangeRequestSuccess:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_request_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.photoExchangeRequestAlreadyPending:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_already_pending
              .t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRequestLikeNotAccepted:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_like_not_accepted
              .t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRequestRequiresSubscription:
        showPaywall(context, intent: PaywallIntent.photoExchange);
      case LikesActionEvent.photoExchangeRequestFailure:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_request_failed.t(context),
          type: SnackBarType.error,
        );
      // Photo-exchange responder
      case LikesActionEvent.photoExchangeAcceptSuccess:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_accept_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.photoExchangeRejectSuccess:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_reject_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.photoExchangeRespondNotFound:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_respond_not_found.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRespondExpired:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_respond_expired.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRespondFailure:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_respond_failed.t(context),
          type: SnackBarType.error,
        );
      // Formal step (stage 1/2) — on send (or already-sent) just open the
      // matchmaker chat; never re-post the card.
      case LikesActionEvent.formalStepSuccess:
      case LikesActionEvent.formalStepAlreadySent:
        _openMatchmakerMessages(context);
      case LikesActionEvent.formalStepFailure:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.likes_matches_action_request_failed.t(context),
          type: SnackBarType.error,
        );
    }
  }

  void _openMatchmakerMessages(BuildContext context) {
    final shell = HomeShellScope.maybeOf(context);
    if (shell != null) {
      shell.openMessagesTab();
      return;
    }
    AppSnackBar.show(
      context,
      message:
          LocaleKeys.likes_matches_stage_matchmaker_will_contact.t(context),
      type: SnackBarType.info,
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranSpacing.s8,
      ),
      child: QeranSectionHeader(title: LocaleKeys.likes_title.t(context)),
    );
  }
}

class _TabBody extends StatelessWidget {
  final LikesState state;
  const _TabBody({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.activeTab) {
      case LikesTab.sent:
        return LikesSentSection(state: state);
      case LikesTab.received:
        return LikesReceivedSection(state: state);
      case LikesTab.matches:
        return MatchesSection(
          state: state,
          onContactMatchmaker: _onContactMatchmaker,
        );
    }
  }

  void _onContactMatchmaker(BuildContext context, String? conversationId) {
    // The user has exactly one matchmaker conversation, resolved by the
    // chat screen via `/api/chat/my-matchmaker`. `conversationId` is null
    // until a formalRequest exists (Stage 0), so we no longer gate on it
    // — the inquiry / formal-step button opens the matchmaker chat at
    // every stage. Preferred path: switch the bottom nav to the Messages
    // tab (preserves navigation state — no extra push).
    final shell = HomeShellScope.maybeOf(context);
    if (shell != null) {
      shell.openMessagesTab();
      return;
    }
    // Non-shell scope (deep link / widget test): route directly when we
    // have an id, else surface the neutral "will contact you" notice.
    if (conversationId != null && conversationId.isNotEmpty) {
      NavigationManager.navigateTo(
        context,
        RouteNames.matchmakerChat,
        arguments: MatchmakerChatScreenArgs(conversationId: conversationId),
      );
      return;
    }
    AppSnackBar.show(
      context,
      message:
          LocaleKeys.likes_matches_stage_matchmaker_will_contact.t(context),
      type: SnackBarType.info,
    );
  }
}

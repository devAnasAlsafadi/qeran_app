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
import 'package:qeran/features/notifications/presentation/widgets/notification_back_row.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_gate_banner.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../widgets/likes_segmented_tabs.dart';
import '../widgets/likes_swipeable_tab_body.dart';
import '../widgets/photo_exchange_limit_sheet.dart';
import 'match_success_screen.dart';

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
            // Reached from a notification, the tab carries a way back to the
            // inbox. A tab has nothing to pop, so the shell reopens it.
            final shell = HomeShellScope.maybeOf(context);
            final fromNotification = shell?.fromNotification ?? false;
            return Column(
              children: [
                if (fromNotification)
                  NotificationBackRow(onBack: shell!.returnToNotifications),
                _Header(),
                const ProfileGateBanner(),
                LikesSegmentedTabs(
                  active: state.activeTab,
                  // Tap path: just write cubit state. `_SwipeableTabBody`
                  // reconciles the PageController in `didUpdateWidget`, so
                  // tap and swipe share one source of truth (`activeTab`).
                  onChanged: context.read<LikesCubit>().switchTab,
                ),
                Expanded(child: LikesSwipeableTabBody(state: state)),
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
      case LikesActionEvent.acceptUnderReview:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_status_pending_review_accept.t(context),
          type: SnackBarType.info,
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
          message: LocaleKeys.likes_matches_action_request_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.photoExchangeRequestAlreadyPending:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_already_pending.t(
            context,
          ),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRequestLikeNotAccepted:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_like_not_accepted.t(
            context,
          ),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRequestRequiresSubscription:
        showPaywall(context, intent: PaywallIntent.photoExchange);
      // Subscribed user hit their plan's photo-exchange cap — an upgrade
      // prompt (NOT a subscribe gate). The sheet reads the current plan +
      // renewal date from the app-wide subscription state.
      case LikesActionEvent.photoExchangeRequestLimitReached:
        showPhotoExchangeLimitSheet(
          context,
          subscription: context.read<CurrentSubscriptionCubit>().subscription,
        );
      case LikesActionEvent.photoExchangeRequestFailure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_failed.t(context),
          type: SnackBarType.error,
        );
      case LikesActionEvent.photoExchangeRequestUnderReview:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_status_pending_review.t(context),
          type: SnackBarType.info,
        );
      // Photo-exchange responder
      case LikesActionEvent.photoExchangeAcceptSuccess:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_accept_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.photoExchangeRejectSuccess:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_reject_success.t(context),
          type: SnackBarType.success,
        );
      case LikesActionEvent.photoExchangeRespondNotFound:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_respond_not_found.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRespondExpired:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_respond_expired.t(context),
          type: SnackBarType.info,
        );
      case LikesActionEvent.photoExchangeRespondFailure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_respond_failed.t(context),
          type: SnackBarType.error,
        );
      // Inquiry / formal step — rebuild the preserved chat tab so the newly
      // posted profile card and text are visible immediately.
      case LikesActionEvent.inquirySuccess:
      case LikesActionEvent.inquiryAlreadySent:
      case LikesActionEvent.formalStepSuccess:
      case LikesActionEvent.formalStepAlreadySent:
        _openMatchmakerMessages(context);
      case LikesActionEvent.inquiryFailure:
      case LikesActionEvent.formalStepFailure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_failed.t(context),
          type: SnackBarType.error,
        );
    }
  }

  void _openMatchmakerMessages(BuildContext context) {
    final shell = HomeShellScope.maybeOf(context);
    if (shell != null) {
      shell.openMessagesTab(refresh: true);
      return;
    }
    AppSnackBar.show(
      context,
      message: LocaleKeys.likes_matches_stage_matchmaker_will_contact.t(
        context,
      ),
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

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
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/widgets/tab_back_row.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_gate_banner.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../blocs/match_actions_cubit.dart';
import '../blocs/match_actions_state.dart';
import 'match_action_snackbars.dart';
import '../blocs/matchmaker_inquiry_cubit.dart';
import '../blocs/matchmaker_inquiry_state.dart';
import '../widgets/likes_segmented_tabs.dart';
import '../widgets/likes_swipeable_tab_body.dart';
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
    // Nested rather than flat: MatchActionsCubit is built from LikesCubit's
    // `loadMatches`, so the outer provider has to exist before the inner ones
    // are created. That ordering IS the one dependency between them.
    return BlocProvider<LikesCubit>(
      create: (_) => sl<LikesCubit>()..primeActiveTab(),
      child: Builder(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<MatchActionsCubit>(
              create: (_) => sl<MatchActionsCubit>(
                param1: context.read<LikesCubit>().loadMatches,
              ),
            ),
            BlocProvider<MatchmakerInquiryCubit>(
              create: (_) => sl<MatchmakerInquiryCubit>(),
            ),
          ],
          child: const _LikesView(),
        ),
      ),
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
        child: BlocListener<MatchActionsCubit, MatchActionsState>(
          listenWhen: (prev, curr) =>
              prev.eventVersion != curr.eventVersion &&
              curr.event != MatchActionEvent.none,
          listener: onMatchActionEvent,
          child: BlocListener<MatchmakerInquiryCubit, MatchmakerInquiryState>(
          listenWhen: (prev, curr) =>
              prev.eventVersion != curr.eventVersion &&
              curr.event != InquiryEvent.none,
          listener: _onInquiryEvent,
          child: BlocConsumer<LikesCubit, LikesState>(
          // Listener only fires on `actionEventVersion` bumps so toasts
          // and the paywall sheet can never re-trigger from an
          // unrelated state change (tab switch, refresh, etc).
          listenWhen: (prev, curr) =>
              prev.actionEventVersion != curr.actionEventVersion &&
              curr.actionEvent != LikesActionEvent.none,
          listener: _onActionEvent,
          builder: (context, state) {
            // Reached from the inbox, the tab carries a way back to it. A tab
            // has nothing to pop, so the shell reopens it. Only that trail
            // lands here — nothing switches TO Likes from Likes.
            final shell = HomeShellScope.maybeOf(context);
            final fromNotification =
                shell?.backTrail == HomeBackTrail.notifications;
            return Column(
              children: [
                if (fromNotification)
                  TabBackRow(onBack: shell!.followBackTrail),
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
        ),
      ),
    );
  }

  /// The inquiry's own outcomes, on their own listener.
  ///
  /// Three arms rather than three of forty. Its enum holds only what this
  /// cubit can emit, so the switch stays exhaustive AND every arm is
  /// reachable — a new inquiry outcome is a compile error here, which is the
  /// property a shared forty-member enum would have buried.
  void _onInquiryEvent(BuildContext context, MatchmakerInquiryState state) {
    switch (state.event) {
      case InquiryEvent.none:
        break;
      // Rebuild the preserved chat tab so the newly posted profile card and
      // text are visible immediately. The formal step does not join this: it
      // posts nothing to the matchmaker, so there would be nothing to show.
      case InquiryEvent.success:
      case InquiryEvent.alreadySent:
        _openMatchmakerMessages(context);
      case InquiryEvent.failure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.likes_matches_action_request_failed.t(context),
          type: SnackBarType.error,
        );
    }
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
    }
  }

  void _openMatchmakerMessages(BuildContext context) {
    final shell = HomeShellScope.maybeOf(context);
    if (shell != null) {
      // Leaves a trail: the compatibility list the user was reading is a tab,
      // so there is nothing to pop back to without one.
      shell.openMessagesTab(refresh: true, trail: HomeBackTrail.likes);
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

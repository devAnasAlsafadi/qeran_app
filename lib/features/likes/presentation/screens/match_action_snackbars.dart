import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/match_actions_state.dart';
import '../widgets/photo_exchange_limit_sheet.dart';

/// Snackbars and sheets for everything done TO a match card.
///
/// Its own file, and its own listener on the screen, because the events split
/// with the cubit. Twenty-nine arms is most of what `likes_screen.dart` used
/// to be; leaving them there would have meant one switch over two cubits'
/// worth of outcomes, which is how a screen file reaches four hundred lines.
///
/// Backend messages are NEVER shown verbatim — every branch uses a localized
/// key.
void onMatchActionEvent(BuildContext context, MatchActionsState state) {
  switch (state.event) {
    case MatchActionEvent.none:
      break;
    // Photo-exchange request (initiator)
    case MatchActionEvent.photoRequestSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_success.t(context),
        type: SnackBarType.success,
      );
    case MatchActionEvent.photoRequestAlreadyPending:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_already_pending.t(
          context,
        ),
        type: SnackBarType.info,
      );
    case MatchActionEvent.photoRequestLikeNotAccepted:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_like_not_accepted.t(
          context,
        ),
        type: SnackBarType.info,
      );
    case MatchActionEvent.photoRequestRequiresSubscription:
      showPaywall(context, intent: PaywallIntent.photoExchange);
    // Subscribed user hit their plan's photo-exchange cap — an upgrade
    // prompt (NOT a subscribe gate). The sheet reads the current plan +
    // renewal date from the app-wide subscription state.
    case MatchActionEvent.photoRequestLimitReached:
      showPhotoExchangeLimitSheet(
        context,
        subscription: context.read<CurrentSubscriptionCubit>().subscription,
      );
    case MatchActionEvent.photoRequestFailure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_failed.t(context),
        type: SnackBarType.error,
      );
    case MatchActionEvent.photoRequestUnderReview:
      AppSnackBar.show(
        context,
        message: LocaleKeys.profile_status_pending_review.t(context),
        type: SnackBarType.info,
      );
    // Photo-exchange responder
    case MatchActionEvent.photoAcceptSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_accept_success.t(context),
        type: SnackBarType.success,
      );
    case MatchActionEvent.photoRejectSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_reject_success.t(context),
        type: SnackBarType.success,
      );
    case MatchActionEvent.photoRespondNotFound:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_respond_not_found.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.photoRespondExpired:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_respond_expired.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.photoRespondFailure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_respond_failed.t(context),
        type: SnackBarType.error,
      );
    // Formal step — the member stays on the card, which the refresh has
    // already moved to "awaiting their approval".
    case MatchActionEvent.formalStepSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_formal_step_request_success.t(
          context,
        ),
        type: SnackBarType.success,
      );
    case MatchActionEvent.formalStepAlreadyPending:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_formal_step_already_pending.t(
          context,
        ),
        type: SnackBarType.info,
      );
    case MatchActionEvent.formalStepNotAllowed:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_formal_step_not_allowed.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.formalStepCaseEnded:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_case_already_ended.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.formalStepUnderReview:
      AppSnackBar.show(
        context,
        message: LocaleKeys.profile_status_pending_review.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.formalStepFailure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_failed.t(context),
        type: SnackBarType.error,
      );
    // Formal step — the receiver answering. Every one of these lands on a
    // card the refresh has already redrawn, so the message only has to
    // explain what happened, not what to do next.
    case MatchActionEvent.formalStepAcceptSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_formal_step_accept_success.t(
          context,
        ),
        type: SnackBarType.success,
      );
    case MatchActionEvent.formalStepRejectSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_case_ended_success.t(
          context,
        ),
        type: SnackBarType.info,
      );
    // Says "no longer available" rather than naming a cause. The server
    // answers FORMAL_STEP_NOT_FOUND both for a request that is genuinely
    // gone AND to anyone who is not its responder, so any wording that
    // explains WHY would be wrong half the time.
    case MatchActionEvent.formalStepRespondNotFound:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_formal_step_respond_not_found.t(
          context,
        ),
        type: SnackBarType.info,
      );
    case MatchActionEvent.formalStepRespondExpired:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_formal_step_respond_expired.t(
          context,
        ),
        type: SnackBarType.info,
      );
    // The same sentence the request path uses for CASE_NOT_ACTIVE — one
    // ending, one way of saying it.
    case MatchActionEvent.formalStepRespondCaseEnded:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_case_already_ended.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.formalStepRespondFailure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_failed.t(context),
        type: SnackBarType.error,
      );
    // Cancel. It reaches the SAME ending a declined formal step does — the
    // server even sends the other member the identical neutral notice — so
    // it says the same sentence rather than a second one meaning the same
    // thing.
    //
    // `info`, not `success`. The member got what they asked for, but a
    // journey ending is not a thing to congratulate them on.
    case MatchActionEvent.cancelSuccess:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_case_ended_success.t(context),
        type: SnackBarType.info,
      );
    // Already over when they tapped. 5d hides the affordance on a case that
    // is not Active, so this means the card was stale — the refresh that
    // follows is what actually fixes it, and this only explains why nothing
    // seemed to happen.
    case MatchActionEvent.cancelAlreadyEnded:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_case_already_ended.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.cancelNotFound:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_case_not_found.t(context),
        type: SnackBarType.info,
      );
    case MatchActionEvent.cancelFailure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_failed.t(context),
        type: SnackBarType.error,
      );
  }
}

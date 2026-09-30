import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/discovery_state.dart';
import 'discovery_deck_animation_controller.dart';

/// Whether the deck has something to announce: its first suggestion (the
/// filter hint's cue), a "start over" notice, or a failed like.
bool discoveryFeedbackListenWhen(DiscoveryState prev, DiscoveryState curr) {
  final firstSuggestion =
      curr is DiscoveryLoaded &&
      curr.current != null &&
      (prev is! DiscoveryLoaded || prev.current == null);
  if (firstSuggestion) return true;
  if (curr is! DiscoveryLoaded) return false;
  // A reset that restored nobody changes nothing else on screen, so the
  // version bump is the only thing that can announce it.
  if (curr.resetNotice != null &&
      (prev is! DiscoveryLoaded ||
          prev.resetNoticeVersion != curr.resetNoticeVersion)) {
    return true;
  }
  if (curr.actionFailureKind == null) return false;
  if (prev is! DiscoveryLoaded) return true;
  return prev.actionErrorVersion != curr.actionErrorVersion;
}

/// Shows the deck's one-off feedback — a "start over" notice or a failed like —
/// and snaps a swiped card back through [deck] when the like didn't go through.
void showDiscoveryFeedback(
  BuildContext context,
  DiscoveryLoaded state,
  DiscoveryDeckAnimationController deck,
) {
  // "Start over" left the screen looking unchanged — it restored
  // nobody, or it failed. A reset that DID restore someone reloads the
  // deck instead, so it never lands here: the returning cards are its
  // own feedback. Returns early so a notice and a like failure can
  // never stack two snackbars.
  final resetNotice = state.resetNotice;
  if (resetNotice != null) {
    AppSnackBar.show(
      context,
      message: switch (resetNotice) {
        DiscoveryResetNotice.nothingToRestore =>
          LocaleKeys.discovery_empty_start_over_nothing,
        DiscoveryResetNotice.failed =>
          LocaleKeys.discovery_empty_start_over_failed,
        DiscoveryResetNotice.offline => LocaleKeys.errors_offline,
      }.t(context),
      // Only the no-op is benign; the other two are failures.
      type: resetNotice == DiscoveryResetNotice.nothingToRestore
          ? SnackBarType.info
          : SnackBarType.error,
    );
    return;
  }
  final kind = state.actionFailureKind;
  if (kind == null) return;
  // Typed dispatch — the cubit has already classified the
  // server's response into one of the five LikeFailureKind
  // variants. The old heuristic (no subscription OR likes
  // remaining == 0) is gone; the server is the source of truth.
  //
  // For the two "no-advance" failures (paywall / network) we
  // also fire `triggerSnapBack` so a swipe-driven attempt that
  // already animated the card off-screen doesn't leave the
  // deck blank. Button-driven failures never ran the eject, so
  // the snap-back call is a no-op there.
  switch (kind) {
    case LikeFailureKind.paywall:
      unawaited(deck.triggerSnapBack());
      showPaywall(context, intent: PaywallIntent.like);
    case LikeFailureKind.alreadyPending:
      // The server's message, not a local string: its duplicate check
      // fires in BOTH directions — you already liked them, or they
      // already liked you — and only it knows which. A local string
      // can only describe one, so it is wrong half the time. The key
      // remains the fallback for an empty message.
      final pending = state.actionError?.trim();
      AppSnackBar.show(
        context,
        message: (pending == null || pending.isEmpty)
            ? LocaleKeys.discovery_like_already_pending.t(context)
            : pending.tOrRaw(context),
        type: SnackBarType.info,
      );
    case LikeFailureKind.genderMismatch:
      AppSnackBar.show(
        context,
        message: LocaleKeys.discovery_like_gender_mismatch.t(context),
        type: SnackBarType.error,
      );
    case LikeFailureKind.userUnavailable:
      AppSnackBar.show(
        context,
        message: LocaleKeys.discovery_like_user_unavailable.t(context),
        type: SnackBarType.info,
      );
    case LikeFailureKind.underReview:
      unawaited(deck.triggerSnapBack());
      AppSnackBar.show(
        context,
        message: LocaleKeys.profile_status_pending_review_like.t(context),
        type: SnackBarType.info,
      );
    case LikeFailureKind.network:
      unawaited(deck.triggerSnapBack());
      AppSnackBar.show(
        context,
        message: LocaleKeys.errors_generic.t(context),
        type: SnackBarType.error,
      );
    case LikeFailureKind.offline:
      unawaited(deck.triggerSnapBack());
      AppSnackBar.show(
        context,
        message: LocaleKeys.errors_offline.t(context),
        type: SnackBarType.error,
      );
  }
}

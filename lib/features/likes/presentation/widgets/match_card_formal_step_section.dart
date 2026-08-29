import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/pending_formal_step.dart';
import 'match_card_formal_step_responder_actions.dart';
import 'match_card_sent_action.dart';
import 'match_pending_countdown_chip.dart';

/// Everything the formal step contributes to a stage-1 or stage-2 card.
///
/// Extracted rather than branched in place: stages 1 and 2 both host the
/// formal step and would otherwise each carry the same three-way branch. They
/// differ in their avatar treatment and their own status line — not in this.
///
/// Three states, and which one applies is the SERVER's answer, never a guess:
///   • nobody asked → the gold CTA.
///   • I asked → the retired "awaiting their approval" button + countdown.
///   • they asked ME → accept / decline + countdown.
///
/// The CTA used to carry a caption — «ستتواصل معك الخطّابة للتنسيق للقاء
/// الرسمي مع الأهل» — removed at the owner's call. Its future tense read as
/// though the step had already happened while the button above it still said
/// «بدء», and it stayed on screen through both post-send states saying the
/// same thing. The button names the action; nothing else was needed.
///
/// The third state's buttons live in
/// `match_card_formal_step_responder_actions.dart`. They were extracted when
/// this file reached 192 lines and sub-step 7 needed to add to it — the
/// standing rule is that the next change splits first rather than squeezing
/// under the cap. This file resolves WHICH state applies; that one draws the
/// only state complex enough to need a widget.
class FormalStepSection {
  const FormalStepSection._({
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryTrailingIcon,
    this.primaryOverride,
    this.topChip,
    this.statusTextOverride,
    this.statusIconOverride,
  });

  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryLoading;
  final IconData? primaryTrailingIcon;
  final Widget? primaryOverride;

  final Widget? topChip;

  /// Set only when the formal step has something more specific to say than
  /// the stage's own subtitle — which is exactly when the member is the one
  /// being waited on.
  final String? statusTextOverride;
  final IconData? statusIconOverride;

  static FormalStepSection resolve(
    BuildContext context, {
    required MatchCard card,
    required VoidCallback? onFormalStep,
    required bool isSending,
    required void Function(int requestId)? onAccept,
    required void Function(int requestId)? onReject,
    required bool isAccepting,
    required bool isRejecting,
  }) {
    final pending = card.pendingFormalStep;

    // Presence of the block proves nothing on its own — a lapsed request keeps
    // arriving with Pending status and a real expiresAt until the server
    // sweeps it, exactly as photo exchange does. The clock decides.
    if (pending != null && pending.isAwaitingMyResponse) {
      return FormalStepSection._(
        primaryOverride: MatchCardResponderActions(
          pending: pending,
          onAccept: onAccept,
          onReject: onReject,
          isAccepting: isAccepting,
          isRejecting: isRejecting,
        ),
        topChip: _chip(pending),
        statusTextOverride:
            LocaleKeys.likes_matches_formal_step_awaiting_you.t(context),
        statusIconOverride: Icons.mark_email_unread_outlined,
      );
    }

    final action = MatchCardSentAction.resolve(
      isSent: card.hasRequestedFormalStep,
      cta: LocaleKeys.likes_matches_formal_step_cta.t(context),
      sentLabel: LocaleKeys.likes_matches_formal_step_sent.t(context),
      unsentVariant: QeranButtonVariant.primary,
      staysTappableWhenSent: false,
    );
    return FormalStepSection._(
      primaryLabel: action.label,
      onPrimaryPressed: action.isEnabled ? onFormalStep : null,
      primaryLoading: isSending,
      primaryTrailingIcon: action.trailingIcon,
      // Only while MY request is genuinely open. Once it is answered the
      // block is gone and the button is reading `caseStage` instead, which
      // carries no deadline to count down.
      topChip: pending != null && pending.isAwaitingResponse
          ? _chip(pending)
          : null,
    );
  }

  static Widget? _chip(PendingFormalStep pending) {
    final secs = pending.remainingSeconds;
    // No onExpired: hitting zero stops the chip and leaves the row alone. A
    // list rearranging itself under a thumb mid-scroll is worse than a stale
    // row the member can pull to refresh.
    return secs == null ? null : MatchPendingCountdownChip(initialSeconds: secs);
  }
}

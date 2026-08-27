import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/pending_formal_step.dart';
import 'match_card_sent_action.dart';
import 'match_pending_countdown_chip.dart';

/// Everything the formal step contributes to a stage-1 or stage-2 card.
///
/// Extracted rather than branched in place: stages 1 and 2 both host the
/// formal step and would otherwise each carry the same three-way branch. They
/// differ in their avatar treatment and their own status line — not in this.
///
/// Three states, and which one applies is the SERVER's answer, never a guess:
///   • nobody asked → the gold CTA, with the helper line under it.
///   • I asked → the retired "awaiting their approval" button + countdown.
///   • they asked ME → accept / decline + countdown, and no helper.
class FormalStepSection {
  const FormalStepSection._({
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryTrailingIcon,
    this.primaryOverride,
    this.helperText,
    this.topChip,
    this.statusTextOverride,
    this.statusIconOverride,
  });

  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryLoading;
  final IconData? primaryTrailingIcon;
  final Widget? primaryOverride;

  /// Null in the responder state. A line explaining what the primary button
  /// sets in motion becomes a caption for BOTH buttons once there are two,
  /// and it only describes one of them.
  final String? helperText;

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
        primaryOverride: _ResponderActions(
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
      helperText: LocaleKeys.likes_matches_formal_step_helper.t(context),
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

/// Accept and decline, STACKED rather than side by side.
///
/// The pair the photo exchange draws puts two `Expanded` buttons in a row,
/// which leaves about 68dp of text each at 320dp — measured, and enough to
/// ellipsise every label we have. «عدم الموافقة وإنهاء التوافق» is more than
/// twice the length of the photo-exchange reject it would sit beside. Full
/// width clears both labels in both languages.
///
/// Decline is on the BOTTOM and outlined. It ends the case, and the button
/// that ends things should not be the one a thumb reaches first.
class _ResponderActions extends StatelessWidget {
  const _ResponderActions({
    required this.pending,
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
  });

  final PendingFormalStep pending;
  final void Function(int requestId)? onAccept;
  final void Function(int requestId)? onReject;
  final bool isAccepting;
  final bool isRejecting;

  @override
  Widget build(BuildContext context) {
    // canAccept / canReject are the server's verdict on each verb separately,
    // so they are read separately. The card never works out whose turn it is.
    final busy = isAccepting || isRejecting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QeranButton(
          label: LocaleKeys.likes_matches_formal_step_action_accept.t(context),
          onPressed: pending.canAccept && !busy
              ? () => onAccept?.call(pending.id)
              : null,
          variant: QeranButtonVariant.primary,
          size: QeranButtonSize.xs,
          loading: isAccepting,
        ),
        QeranSpacing.vs8,
        QeranButton(
          label: LocaleKeys.likes_matches_formal_step_action_reject.t(context),
          onPressed: pending.canReject && !busy
              ? () => _confirmReject(context)
              : null,
          variant: QeranButtonVariant.secondary,
          size: QeranButtonSize.xs,
          loading: isRejecting,
        ),
      ],
    );
  }

  /// Declining ends the compatibility case outright — there is no matchmaker
  /// hand-off the way a rejected photo exchange has one, and no way back. It
  /// also sits directly under the accept button, so a mis-tap is a real way
  /// to lose a case.
  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.likes_matches_formal_step_reject_confirm_title.t(
        context,
      ),
      message: LocaleKeys.likes_matches_formal_step_reject_confirm_message.t(
        context,
      ),
      confirmLabel: LocaleKeys.likes_matches_formal_step_reject_confirm_action
          .t(context),
    );
    if (!confirmed) return;
    onReject?.call(pending.id);
  }
}

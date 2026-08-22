import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

/// How a "share this into the matchmaker chat" CTA reads once it has been
/// sent. Three buttons ask this — the stage-0 inquiry and the stage-1/2
/// formal step — and they had drifted into three different answers. This is
/// the one answer.
///
/// The button stays ENABLED after sending, deliberately. A second tap does
/// not re-send: the cubit's guard turns it into `inquiryAlreadySent` /
/// `formalStepAlreadySent`, which the screen routes to the matchmaker chat.
/// The sent button is therefore the way back to the message it posted.
///
/// Disabling it would claim a permanence the state does not have. "Sent"
/// lives in an in-memory set on `LikesState` with no server field behind it
/// — sending only shares a card and posts a text; `MatchCard.formalRequest`
/// is the matchmaker's own case record, not a receipt for this tap. So it
/// survives a refresh but not a restart, and a greyed-out button that
/// quietly comes back to life reads as a bug.
class MatchCardSentAction {
  final String label;
  final QeranButtonVariant variant;

  /// Drawn only once sent. With the button still live, the checkmark is what
  /// carries "done" — the label alone would leave it looking unpressed.
  final IconData? trailingIcon;

  const MatchCardSentAction({
    required this.label,
    required this.variant,
    required this.trailingIcon,
  });

  /// What is shared is the TREATMENT, never the words. [sentLabel] stays the
  /// caller's, because asking a question and making a formal request are
  /// different things to have done, and the member should read which one they
  /// did — that distinction is business content, not visual style.
  ///
  /// [unsentVariant] differs by stage for the same reason: the inquiry is a
  /// secondary action sitting under the photo-exchange CTA (wine), while the
  /// formal step is its card's primary (gold).
  factory MatchCardSentAction.resolve({
    required bool isSent,
    required String cta,
    required String sentLabel,
    required QeranButtonVariant unsentVariant,
  }) {
    if (!isSent) {
      return MatchCardSentAction(
        label: cta,
        variant: unsentVariant,
        trailingIcon: null,
      );
    }
    return MatchCardSentAction(
      label: sentLabel,
      variant: QeranButtonVariant.neutral,
      trailingIcon: Icons.check_rounded,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

/// How a "share this into the matchmaker chat" CTA reads once it has been
/// sent. Three buttons ask this — the stage-0 inquiry and the stage-1/2
/// formal step — and they had drifted into three different answers. This is
/// the one answer.
///
/// Whether the sent button still accepts taps is the one thing the two
/// callers answer differently, and they answer differently because a second
/// tap MEANS something different.
///
/// The INQUIRY stays tappable. Its second tap does not re-send — the cubit's
/// guard turns it into `inquiryAlreadySent`, which the screen routes to the
/// matchmaker chat — so the sent button is the way back to the message it
/// posted. Disabling it would also claim a permanence the state does not
/// have: "sent" lives in an in-memory set on `LikesState` with nothing behind
/// it, so it survives a refresh but not a restart, and a greyed-out button
/// that quietly comes back to life reads as a bug.
///
/// The FORMAL STEP is disabled once sent. `MatchCard.hasRequestedFormalStep`
/// reads the server's own `pendingFormalStep`, so "sent" is durable and a
/// greyed-out button will not spring back. And its second tap has nowhere
/// useful to go: it reaches the server and returns
/// `FORMAL_STEP_ALREADY_PENDING`, restating what the label already says at
/// the cost of a round trip. A button that does nothing worth doing is a
/// weaker state than one that plainly cannot be pressed.
class MatchCardSentAction {
  final String label;
  final QeranButtonVariant variant;

  /// Drawn only once sent. On a still-live button the checkmark is what
  /// carries "done" — the label alone would leave it looking unpressed.
  final IconData? trailingIcon;

  /// False only for a sent action whose caller asked to retire it. Callers
  /// pass `onPressed` through this rather than reading [label], so the
  /// enabled state and the words can never disagree.
  final bool isEnabled;

  const MatchCardSentAction({
    required this.label,
    required this.variant,
    required this.trailingIcon,
    this.isEnabled = true,
  });

  /// What is shared is the TREATMENT, never the words. [sentLabel] stays the
  /// caller's, because asking a question and making a formal request are
  /// different things to have done, and the member should read which one they
  /// did — that distinction is business content, not visual style.
  ///
  /// [unsentVariant] differs by stage for the same reason: the inquiry is a
  /// secondary action sitting under the photo-exchange CTA (wine), while the
  /// formal step is its card's primary (gold).
  ///
  /// [staysTappableWhenSent] defaults to the inquiry's answer because that is
  /// the older caller; the formal step opts out. See the class doc for why
  /// this is the one thing they do not share.
  factory MatchCardSentAction.resolve({
    required bool isSent,
    required String cta,
    required String sentLabel,
    required QeranButtonVariant unsentVariant,
    bool staysTappableWhenSent = true,
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
      isEnabled: staysTappableWhenSent,
    );
  }
}

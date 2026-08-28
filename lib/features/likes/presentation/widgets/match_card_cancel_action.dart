import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_case_stage.dart';
import '../../domain/entities/match_case_status.dart';

/// The cancel X in a match card's header — a member's way out of a
/// compatibility case at any stage, without waiting for the other side.
///
/// One resolver rather than a branch repeated in each stage card, following
/// [FormalStepSection]. All three stages ask the same three-clause question,
/// and a rule about ending someone's compatibility case is not one to hold
/// three copies of.
class MatchCardCancelAction {
  const MatchCardCancelAction._();

  /// Whether this card offers a way to end the case.
  ///
  /// Three clauses, none of them redundant:
  ///
  ///  1. **`caseStatus == active`**, and deliberately not `!caseStatus.isEnded`
  ///     — the two differ on [MatchCaseStatus.unknown], a status the server
  ///     sent and this client has never heard of. `isEnded` would treat it as
  ///     live and offer to cancel something we cannot describe; `== active`
  ///     omits rather than guesses.
  ///
  ///  2. **not [MatchCaseStage.marriageCompleted]**, which clause 1 does NOT
  ///     already cover. `caseStatus` is how a case ENDED and `caseStage` is
  ///     how far it GOT — separate fields precisely because they answer
  ///     different questions, so a case can stand on the marriage stage while
  ///     its status is still `active`. Offering to end a completed marriage is
  ///     the one place the X would be worse than absent.
  ///
  ///  3. **no formal step awaiting MY answer**. That card already carries
  ///     «عدم الموافقة وإنهاء التوافق», which ends the case by itself. Two
  ///     controls for one irreversible outcome, one of them a bare glyph, is
  ///     a mis-tap waiting to happen. `isAwaitingMyResponse` was written in
  ///     sub-step 4b naming this exact exception.
  static bool isAvailable(MatchCard card) {
    if (card.caseStatus != MatchCaseStatus.active) return false;
    if (card.caseStage == MatchCaseStage.marriageCompleted) return false;
    if (card.pendingFormalStep?.isAwaitingMyResponse ?? false) return false;
    return true;
  }

  /// The X itself, or null when this card offers no way out.
  ///
  /// Returns a widget rather than a bool so the three stages pass it straight
  /// to the scaffold without each deciding what "available" should look like.
  static Widget? resolve(
    BuildContext context, {
    required MatchCard card,
    required VoidCallback? onCancel,
    required bool isCancelling,
  }) {
    if (onCancel == null || !isAvailable(card)) return null;
    return _CancelButton(onCancel: onCancel, isCancelling: isCancelling);
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel, required this.isCancelling});

  final VoidCallback onCancel;
  final bool isCancelling;

  /// Small enough to leave the name its row, large enough to hit. The header
  /// budget is tight at 320dp — see `match_card_header_layout_test`.
  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.likes_matches_case_end_confirm_action.t(context);
    return SizedBox(
      width: _size,
      height: _size,
      child: isCancelling
          ? const Padding(
              padding: EdgeInsets.all(6),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: QeranColors.inkMuted,
              ),
            )
          // Its own InkWell, which is also what keeps the tap off the card's
          // onOpenProfile: the card wraps everything in an InkWell, and a
          // nested one absorbs the gesture rather than letting it through to
          // open a profile the member was trying to leave.
          : Semantics(
              button: true,
              label: label,
              child: InkWell(
                onTap: () => _confirm(context),
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: QeranColors.inkMuted,
                ),
              ),
            ),
    );
  }

  /// Ending a case cannot be undone and the control is a bare glyph in a
  /// corner, so the dialog is not optional politeness — it is the only thing
  /// standing between a mis-tap and a lost case.
  ///
  /// Same copy as the formal-step decline, on purpose: both reach the same
  /// ending, and two sentences for one consequence is how they drift.
  Future<void> _confirm(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.likes_matches_case_end_confirm_title.t(context),
      message: LocaleKeys.likes_matches_case_end_confirm_message.t(context),
      confirmLabel: LocaleKeys.likes_matches_case_end_confirm_action.t(context),
    );
    if (!confirmed) return;
    onCancel();
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/pending_formal_step.dart';

/// Accept and decline, STACKED rather than side by side.
///
/// Public and in its own file since sub-step 7: it was `_ResponderActions`
/// inside `match_card_formal_step_section.dart` until that file hit 192 lines
/// and had to split before growing. Nothing about the widget changed in the
/// move.
///
/// The pair the photo exchange draws puts two `Expanded` buttons in a row,
/// which leaves about 68dp of text each at 320dp — measured, and enough to
/// ellipsise every label we have. «عدم الموافقة وإنهاء التوافق» is more than
/// twice the length of the photo-exchange reject it would sit beside. Full
/// width clears both labels in both languages.
///
/// Decline is on the BOTTOM and outlined. It ends the case, and the button
/// that ends things should not be the one a thumb reaches first.
class MatchCardResponderActions extends StatelessWidget {
  const MatchCardResponderActions({
    super.key,
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
      title: LocaleKeys.likes_matches_case_end_confirm_title.t(
        context,
      ),
      message: LocaleKeys.likes_matches_case_end_confirm_message.t(
        context,
      ),
      confirmLabel: LocaleKeys.likes_matches_case_end_confirm_action
          .t(context),
    );
    if (!confirmed) return;
    onReject?.call(pending.id);
  }
}

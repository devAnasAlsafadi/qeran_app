import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Identity-styled confirm for deleting a user note (no Material defaults).
/// Pops `true` to confirm, `false`/dismiss to cancel. Mirrors the approve
/// confirm dialog on the profile action bar.
Future<bool?> showDeleteNoteConfirm(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteNoteConfirmDialog(),
  );
}

class _DeleteNoteConfirmDialog extends StatelessWidget {
  const _DeleteNoteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: QeranColors.paper,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.cardR),
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.matchmaker_notes_delete_confirm_title.t(context),
              style: QeranTypography.title,
            ),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.matchmaker_notes_delete_confirm_message.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs20,
            Row(
              children: [
                Expanded(
                  child: QeranButton(
                    label:
                        LocaleKeys.matchmaker_profile_action_cancel.t(context),
                    variant: QeranButtonVariant.ghost,
                    size: QeranButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                QeranSpacing.hs12,
                Expanded(
                  child: QeranButton(
                    label: LocaleKeys.matchmaker_notes_delete.t(context),
                    variant: QeranButtonVariant.destructive,
                    size: QeranButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

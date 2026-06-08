import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Confirm deleting a user note — the unified [QeranConfirmDialog]. Returns
/// `true` to confirm, `false`/dismiss to cancel.
Future<bool> showDeleteNoteConfirm(BuildContext context) {
  return QeranConfirmDialog.show(
    context,
    title: LocaleKeys.matchmaker_notes_delete_confirm_title.t(context),
    message: LocaleKeys.matchmaker_notes_delete_confirm_message.t(context),
    confirmLabel: LocaleKeys.matchmaker_notes_delete.t(context),
    cancelLabel: LocaleKeys.matchmaker_profile_action_cancel.t(context),
    icon: Icons.delete_outline_rounded,
  );
}

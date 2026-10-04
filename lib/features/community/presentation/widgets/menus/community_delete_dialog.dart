import 'package:flutter/material.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Deleting a comment or a reply asks first (E8, E8b): a comment goes with
/// every reply under it (D16); a reply's dialog says «الرد», as its menu row
/// and its toast do (S14). True when the member confirms.
Future<bool> confirmCommunityDelete(
  BuildContext context,
  ReportContentKind kind,
) {
  final reply = kind == ReportContentKind.reply;
  return QeranConfirmDialog.show(
    context,
    title: (reply
            ? LocaleKeys.community_delete_reply_title
            : LocaleKeys.community_delete_title)
        .t(context),
    message: (reply
            ? LocaleKeys.community_delete_reply_body
            : LocaleKeys.community_delete_body)
        .t(context),
    confirmLabel: LocaleKeys.common_delete.t(context),
    cancelLabel: LocaleKeys.common_cancel.t(context),
    icon: Icons.delete_outline_rounded,
  );
}

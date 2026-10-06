import 'package:flutter/material.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Deleting a comment or a reply asks first (E8, E8b): a comment goes with
/// every reply under it (D16); a reply's dialog says «الرد», as its menu row
/// and its toast do (S14). Someone else's item — only the post's author may
/// delete one — reads «هذا التعليق» / «هذا الرد», not «تعليقك» (E4, E5).
/// True when the reader confirms.
Future<bool> confirmCommunityDelete(
  BuildContext context,
  ReportContentKind kind, {
  bool mine = true,
}) {
  final reply = kind == ReportContentKind.reply;
  return QeranConfirmDialog.show(
    context,
    title: (reply
            ? LocaleKeys.community_delete_reply_title
            : LocaleKeys.community_delete_title)
        .t(context),
    message: _body(reply: reply, mine: mine).t(context),
    confirmLabel: LocaleKeys.common_delete.t(context),
    cancelLabel: LocaleKeys.common_cancel.t(context),
    icon: Icons.delete_outline_rounded,
  );
}

String _body({required bool reply, required bool mine}) =>
    switch ((reply, mine)) {
      (false, true) => LocaleKeys.community_delete_body,
      (true, true) => LocaleKeys.community_delete_reply_body,
      (false, false) => LocaleKeys.community_delete_others_body,
      (true, false) => LocaleKeys.community_delete_others_reply_body,
    };

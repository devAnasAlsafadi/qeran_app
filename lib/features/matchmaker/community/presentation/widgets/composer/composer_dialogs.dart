import 'package:flutter/material.dart';

import '../../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// × or back on a draft with something in it (C11).
Future<bool> confirmDiscardDraft(BuildContext context) =>
    QeranConfirmDialog.show(
      context,
      title: LocaleKeys.matchmaker_community_discard_title.t(context),
      message: LocaleKeys.matchmaker_community_discard_body.t(context),
      confirmLabel: LocaleKeys.matchmaker_community_discard.t(context),
      cancelLabel: LocaleKeys.matchmaker_community_keep_writing.t(context),
      icon: Icons.edit_off_rounded,
    );

/// × or back while her media goes up (D2b): stopping returns the draft.
Future<bool> confirmCancelUpload(BuildContext context) =>
    QeranConfirmDialog.show(
      context,
      title: LocaleKeys.matchmaker_community_cancel_upload_title.t(context),
      message: LocaleKeys.matchmaker_community_cancel_upload_body.t(context),
      confirmLabel: LocaleKeys.matchmaker_community_cancel_upload.t(context),
      cancelLabel: LocaleKeys.matchmaker_community_keep_uploading.t(context),
      icon: Icons.cloud_off_rounded,
    );

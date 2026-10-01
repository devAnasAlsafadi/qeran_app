import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The one Block confirmation — a profile's ⋮ and a Community comment's ⋮
/// ask the same question in the same words. True when the member confirms.
Future<bool> confirmBlockMember(BuildContext context) => QeranConfirmDialog.show(
      context,
      title: LocaleKeys.block_confirm_title.t(context),
      message: LocaleKeys.block_confirm_body.t(context),
      confirmLabel: LocaleKeys.block_confirm_button.t(context),
      cancelLabel: LocaleKeys.common_cancel.t(context),
      icon: Icons.block_rounded,
    );

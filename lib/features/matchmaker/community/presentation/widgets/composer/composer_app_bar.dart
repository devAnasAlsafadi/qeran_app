import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// «منشور جديد» with × at the start and «نشر» at the end (C1, S1, S10).
PreferredSizeWidget composerAppBar(
  BuildContext context, {
  required VoidCallback onClose,
  required VoidCallback? onPublish,
  required bool busy,
}) => QeranAppBar(
  title: LocaleKeys.matchmaker_community_new_post.t(context),
  close: true,
  onBack: onClose,
  background: QeranColors.paper,
  actions: [
    Padding(
      padding: const EdgeInsetsDirectional.only(end: QeranSpacing.s12),
      child: QeranButton(
        label: LocaleKeys.matchmaker_community_publish.t(context),
        onPressed: onPublish,
        variant: QeranButtonVariant.primaryGold,
        size: QeranButtonSize.compact,
        fullWidth: false,
        loading: busy,
      ),
    ),
  ],
);

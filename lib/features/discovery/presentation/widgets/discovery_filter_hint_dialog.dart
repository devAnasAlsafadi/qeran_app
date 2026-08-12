import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

Future<void> showDiscoveryFilterHintDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: QeranColors.paper,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.cardR),
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.wine08,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.tune_rounded,
                color: QeranColors.wine,
                size: 28,
              ),
            ),
            QeranSpacing.vs16,
            Text(
              LocaleKeys.discovery_filter_hint_title.t(dialogContext),
              textAlign: TextAlign.center,
              style: QeranTypography.title,
            ),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.discovery_filter_hint_body.t(dialogContext),
              textAlign: TextAlign.center,
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
            ),
            QeranSpacing.vs20,
            QeranButton(
              label: LocaleKeys.discovery_filter_hint_confirm.t(dialogContext),
              variant: QeranButtonVariant.primaryWine,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// DS-pure confirm dialog for the account's destructive actions (logout +
/// deactivate). Ghost cancel + destructive confirm. Pops `true` to confirm.
class MatchmakerConfirmDialog extends StatelessWidget {
  const MatchmakerConfirmDialog({
    super.key,
    required this.titleKey,
    required this.messageKey,
    required this.confirmKey,
  });

  final String titleKey;
  final String messageKey;
  final String confirmKey;

  static Future<bool> show(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    required String confirmKey,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MatchmakerConfirmDialog(
        titleKey: titleKey,
        messageKey: messageKey,
        confirmKey: confirmKey,
      ),
    );
    return result ?? false;
  }

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
            Text(titleKey.t(context), style: QeranTypography.title),
            QeranSpacing.vs8,
            Text(messageKey.t(context), style: QeranTypography.body),
            QeranSpacing.vs20,
            Row(
              children: [
                Expanded(
                  child: QeranButton(
                    label: LocaleKeys.common_cancel.t(context),
                    variant: QeranButtonVariant.ghost,
                    size: QeranButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                QeranSpacing.hs12,
                Expanded(
                  child: QeranButton(
                    label: confirmKey.t(context),
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

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class OathFooter extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onSwear;

  const OathFooter({
    super.key,
    required this.isChecked,
    required this.onSwear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.auth_oath_footer.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.caption.copyWith(
            color: QeranColors.inkMuted,
            height: 1.6,
          ),
        ),
        QeranSpacing.vs24,
        // Gating is unchanged: `onPressed: null` until the oath is agreed.
        // QeranButton renders that disabled state as the wine CTA at 50 %
        // opacity (faded plum) — on-brand, not generic grey.
        QeranButton(
          label: LocaleKeys.auth_oath_button.t(context),
          variant: QeranButtonVariant.primaryWine,
          onPressed: isChecked ? onSwear : null,
        ),
        QeranSpacing.vs24,
      ],
    );
  }
}

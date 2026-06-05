import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: QeranColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
          child: Text(
            LocaleKeys.common_or.t(context),
            style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
          ),
        ),
        const Expanded(child: Divider(color: QeranColors.divider)),
      ],
    );
  }
}

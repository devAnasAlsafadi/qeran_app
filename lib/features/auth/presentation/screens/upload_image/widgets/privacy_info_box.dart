import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class PrivacyInfoBox extends StatelessWidget {
  const PrivacyInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.wine20, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              LocaleKeys.auth_photo_privacy_note.t(context),
              style: QeranTypography.bodySm,
            ),
          ),
          QeranSpacing.hs8,
          const Icon(Icons.lock_rounded, color: QeranColors.wine, size: 24),
        ],
      ),
    );
  }
}

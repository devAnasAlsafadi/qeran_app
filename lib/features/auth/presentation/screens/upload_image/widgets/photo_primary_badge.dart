import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// "رئيسية" (primary) tag pinned to a photo tile's bottom-start corner.
class PhotoPrimaryBadge extends StatelessWidget {
  const PhotoPrimaryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: QeranColors.wine,
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(QeranRadii.control),
          bottomStart: Radius.circular(QeranRadii.control),
        ),
      ),
      child: Text(
        LocaleKeys.auth_photo_primary_label.t(context),
        style: QeranTypography.caption.copyWith(color: QeranColors.paper),
      ),
    );
  }
}

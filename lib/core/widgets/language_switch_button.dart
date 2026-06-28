import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

enum LanguageSwitchVariant { light, dark }

class LanguageSwitchButton extends StatelessWidget {
  final LanguageSwitchVariant variant;

  const LanguageSwitchButton({
    super.key,
    this.variant = LanguageSwitchVariant.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = variant == LanguageSwitchVariant.light;
    final iconColor = isLight ? QeranColors.paper : QeranColors.wine;
    final borderColor =
        isLight ? QeranColors.paper.withValues(alpha: 0.5) : QeranColors.wine20;
    final bgColor =
        isLight ? QeranColors.paper.withValues(alpha: 0.1) : QeranColors.wine06;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: QeranRadii.pill,
        border: Border.all(color: borderColor),
      ),
      child: PopupMenuButton<Locale>(
        initialValue: context.locale,
        tooltip: 'Select Language',
        offset: const Offset(0, 45),
        shape: const RoundedRectangleBorder(
          borderRadius: QeranRadii.controlR,
        ),
        onSelected: (Locale newLocale) {
          context.setLocale(newLocale);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s8,
          ),
          child: Icon(Icons.language_rounded, size: 24, color: iconColor),
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
          PopupMenuItem<Locale>(
            value: const Locale('en'),
            child: Text(
              'English',
              style: QeranTypography.label.copyWith(color: QeranColors.wine),
            ),
          ),
          PopupMenuItem<Locale>(
            value: const Locale('ar'),
            child: Text(
              'العربية',
              style: QeranTypography.label.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}

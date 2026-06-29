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

    return PopupMenuButton<Locale>(
      initialValue: context.locale,
      tooltip: 'Select Language',
      offset: const Offset(0, 45),
      shape: const RoundedRectangleBorder(
        borderRadius: QeranRadii.controlR,
      ),
      onSelected: (Locale newLocale) {
        context.setLocale(newLocale);
      },
      child: isLight ? _buildLightChild() : _buildDarkChild(context),
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
    );
  }

  // Onboarding variant: icon-only pill over imagery (unchanged).
  Widget _buildLightChild() {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper.withValues(alpha: 0.1),
        borderRadius: QeranRadii.pill,
        border: Border.all(color: QeranColors.paper.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      child: const Icon(
        Icons.language_rounded,
        size: 24,
        color: QeranColors.paper,
      ),
    );
  }

  // Login variant: labeled pill — current language + chevron signals the
  // dropdown. Resolves the label from the active locale (RTL-safe via Row).
  Widget _buildDarkChild(BuildContext context) {
    final bool isArabic = context.locale.languageCode == 'ar';
    final String label = isArabic ? 'العربية' : 'English';

    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.pill,
        border: Border.all(color: QeranColors.wine12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language_rounded, size: 16, color: QeranColors.wine),
          QeranSpacing.hs8,
          Text(
            label,
            style: QeranTypography.label.copyWith(color: QeranColors.wine),
          ),
          QeranSpacing.hs4,
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: QeranColors.wine,
          ),
        ],
      ),
    );
  }
}

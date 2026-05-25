import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

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
    final textColor = isLight ? AppColors.white : AppColors.primary;
    final borderColor = isLight ? AppColors.white.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.2);
    final bgColor = isLight ? AppColors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: PopupMenuButton<Locale>(
        initialValue: context.locale,
        tooltip: 'Select Language',
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (Locale newLocale) {
          context.setLocale(newLocale);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p12, vertical: AppDimens.p8),
          child: Icon(
            Icons.language,
            size: 24,
            color: textColor,
          ),
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
          PopupMenuItem<Locale>(
            value: const Locale('en'),
            child: Text(
              'English',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          PopupMenuItem<Locale>(
            value: const Locale('ar'),
            child: Text(
              'العربية',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

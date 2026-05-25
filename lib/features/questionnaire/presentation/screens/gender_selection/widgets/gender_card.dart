import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/utils/app_dimens.dart';

class GenderCard extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderCard({
    super.key,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMale = gender == Gender.male;
    final String imageAsset = isMale ? AppAssets.male : AppAssets.female;
    final String label = isMale
        ? LocaleKeys.questionnaire_gender_male.t(context)
        : LocaleKeys.questionnaire_gender_female.t(context);
    final Color cardBg = isMale
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFF8E8EE);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppDimens.borderRadius16,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2ABFE8)
                      : AppColors.border,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.p12),
            Text(
              label,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

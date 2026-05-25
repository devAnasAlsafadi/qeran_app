import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Premium agreement row — custom 24×24 burgundy check box (no Material
/// `Checkbox`), an affirmation pill that softly tints in burgundy when
/// the user has agreed, and a tappable full-width label. Logic identical
/// to the previous version: a single boolean callback fires on toggle.
class OathCheckboxRow extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const OathCheckboxRow({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!isChecked),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p12,
          ),
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: isChecked ? 0.20 : 0.10,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _OathCheckBox(isChecked: isChecked),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Text(
                  LocaleKeys.auth_oath_checkbox.t(context),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OathCheckBox extends StatelessWidget {
  final bool isChecked;
  const _OathCheckBox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isChecked ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isChecked
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: isChecked ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: const Icon(
          Icons.check_rounded,
          size: 16,
          color: AppColors.white,
        ),
      ),
    );
  }
}

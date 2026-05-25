import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

/// Small rounded label used in the profile card to surface quick facts:
/// religion, height, weight, etc.
class ProfileTagChip extends StatelessWidget {
  final String label;

  const ProfileTagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p4 + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.r16 + 4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

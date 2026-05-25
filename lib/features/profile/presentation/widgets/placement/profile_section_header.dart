import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

/// Burgundy icon + bold label. Used by every section of the full
/// profile body so the rendered surface reads as one continuous layout
/// rather than a list of cards.
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppDimens.p4 + 2),
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileSectionDivider extends StatelessWidget {
  const ProfileSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p20),
      child: Container(
        height: 1,
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Inline "{n}% compatibility" pill rendered above the placements on
/// the other-profile screen. Hidden when [percent] is 0 (server's
/// "not scored" sentinel) — the parent decides whether to render the
/// card at all.
class MatchingScoreCard extends StatelessWidget {
  final double percent;
  const MatchingScoreCard({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    final rounded = percent.round();
    final label = context.tr(
      LocaleKeys.profile_compatibility_label,
      namedArgs: {'percent': '$rounded'},
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p20,
        vertical: AppDimens.p8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppDimens.p12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimens.r12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppDimens.p8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

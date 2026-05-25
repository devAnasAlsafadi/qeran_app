import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Shown when the deck is empty (`profiles.isEmpty`) or exhausted
/// (`currentIndex >= profiles.length`).
class DiscoveryEmptyView extends StatelessWidget {
  const DiscoveryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 72,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              LocaleKeys.discovery_empty_title.t(context),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.p8),
            Text(
              LocaleKeys.discovery_empty_subtitle.t(context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

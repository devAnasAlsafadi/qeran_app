import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Centered overlay on the blurred image (per Figma `home.png`):
/// a gold lock icon on a translucent dark circular backdrop, with a
/// gold "photo available upon mutual interest" line beneath it. The
/// string is locale-driven.
class DiscoveryPrivacyMessage extends StatelessWidget {
  const DiscoveryPrivacyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.black.withValues(alpha: 0.35),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            LocaleKeys.discovery_privacy_message.t(context),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

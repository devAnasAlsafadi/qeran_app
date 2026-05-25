import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class ProfileDetailsNotAvailableView extends StatelessWidget {
  const ProfileDetailsNotAvailableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppDimens.p12),
            Text(
              LocaleKeys.profile_not_available.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

class PrivacyInfoBox extends StatelessWidget {
  const PrivacyInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDimens.paddingAll16,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppDimens.borderRadius8,
        border: Border.all(color: AppColors.blue, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              LocaleKeys.auth_photo_privacy_note.t(context),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p8),
          const Icon(Icons.lock, color: AppColors.grey, size: 24),
        ],
      ),
    );
  }
}

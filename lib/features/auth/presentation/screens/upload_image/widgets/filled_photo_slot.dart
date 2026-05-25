import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

class FilledPhotoSlot extends StatelessWidget {
  final int index;
  final File file;
  final bool isPrimary;
  final bool isUploading;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  const FilledPhotoSlot({
    super.key,
    required this.index,
    required this.file,
    required this.isPrimary,
    required this.isUploading,
    required this.onRemove,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: AppDimens.borderRadius12,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        if (isPrimary)
          PositionedDirectional(
            bottom: 0,
            start: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p12,
                vertical: AppDimens.p4,
              ),
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: Radius.circular(8),
                  bottomStart: Radius.circular(AppDimens.p12),
                ),
              ),
              child: Text(
                LocaleKeys.auth_photo_primary_label.t(context),
                style: AppTextStyles.caption.copyWith(color: AppColors.white),
              ),
            ),
          ),
        if (!isUploading)
          PositionedDirectional(
            top: 4,
            end: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        if (!isPrimary && !isUploading)
          Positioned.fill(
            child: GestureDetector(
              onTap: onSetPrimary,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.2),
                  borderRadius: AppDimens.borderRadius12,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import 'dashed_rect_painter.dart';

class EmptyPhotoSlot extends StatelessWidget {
  final bool isUploading;
  final int index;
  final VoidCallback onAddTap;

  const EmptyPhotoSlot({
    super.key,
    required this.isUploading,
    required this.index,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onAddTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DashedRectPainter(
                color: AppColors.primary,
                strokeWidth: 1.5,
                gap: 5.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.transparent,
                  borderRadius: AppDimens.borderRadius12,
                ),
                child: const Center(
                  child: Icon(Icons.add, color: AppColors.primary, size: 28),
                ),
              ),
            ),
          ),
          if (index == 0)
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
        ],
      ),
    );
  }
}

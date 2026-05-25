import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_image.dart';
import 'like_blurred_image.dart';

/// MVP gallery — shown when the user taps the avatar on a stage-1
/// Match card. Renders the full server-ordered image list with the
/// per-image blur flag honored. No tap-to-zoom yet; polish lands in a
/// follow-up.
Future<void> showMatchGallerySheet(
  BuildContext context, {
  required List<MatchImage> images,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: const Color(0x59431C33),
    useSafeArea: true,
    builder: (_) => _MatchGallerySheet(images: images),
  );
}

class _MatchGallerySheet extends StatelessWidget {
  final List<MatchImage> images;
  const _MatchGallerySheet({required this.images});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppDimens.p16,
            AppDimens.p12,
            AppDimens.p16,
            AppDimens.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(),
              const SizedBox(height: AppDimens.p12),
              Text(
                LocaleKeys.likes_matches_gallery_title.t(context),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimens.p12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(top: AppDimens.p8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimens.p12,
                    crossAxisSpacing: AppDimens.p12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final img = images[index];
                    return LikeBlurredImage(
                      url: img.url,
                      blur: img.isBlurred,
                      size: null,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(18),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

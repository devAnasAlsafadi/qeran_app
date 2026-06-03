import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_image.dart';
import 'like_blurred_image.dart';

/// MVP gallery — shown when the user taps the avatar on a stage-1 Match
/// card. Renders the full server-ordered image list with the per-image
/// blur flag honored. No tap-to-zoom yet; polish lands in a follow-up.
Future<void> showMatchGallerySheet(
  BuildContext context, {
  required List<MatchImage> images,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
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
            color: QeranColors.paper,
            borderRadius: QeranRadii.domeTop,
          ),
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s16,
            QeranSpacing.s12,
            QeranSpacing.s16,
            QeranSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: QeranSpacing.s12),
              Text(
                LocaleKeys.likes_matches_gallery_title.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.title.copyWith(color: QeranColors.wine),
              ),
              const SizedBox(height: QeranSpacing.s12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(top: QeranSpacing.s8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: QeranSpacing.s12,
                    crossAxisSpacing: QeranSpacing.s12,
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
                      borderRadius: QeranRadii.cardR,
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
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: QeranColors.wine.withValues(alpha: 0.30),
          borderRadius: QeranRadii.pill,
        ),
      ),
    );
  }
}

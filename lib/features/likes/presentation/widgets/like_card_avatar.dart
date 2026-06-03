import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/like_profile_image.dart';

/// Circular avatar with a gold ring. Soft-blurs the photo when the
/// server marks it [LikeProfileImage.isBlurred]; falls back to a wine
/// person glyph when there's no image.
class LikeCardAvatar extends StatelessWidget {
  final LikeProfileImage? image;
  final double size;
  const LikeCardAvatar({super.key, required this.image, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final url = image?.url;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.5),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s2),
      child: ClipOval(
        child: Container(
          color: QeranColors.wine06,
          alignment: Alignment.center,
          child: url == null || url.isEmpty
              ? const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: QeranColors.wine,
                )
              : _MaybeBlurredImage(url: url, blur: image?.isBlurred ?? false),
        ),
      ),
    );
  }
}

class _MaybeBlurredImage extends StatelessWidget {
  final String url;
  final bool blur;
  const _MaybeBlurredImage({required this.url, required this.blur});

  // Soft blur — strong enough to obscure features without wiping the
  // image into a uniform disc; matches the Figma "silhouette" reference.
  static const double _sigma = 6.0;

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person_rounded,
        size: 36,
        color: QeranColors.inkMuted,
      ),
    );
    if (!blur) return image;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma),
      child: image,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/like_profile_image.dart';
import 'like_blurred_image.dart';

/// Circular avatar with a gold ring for the Likes / Interests rows.
///
/// Hidden photos render the server's blurred thumbnail; only when the backend
/// omits one does the client filter stand in. Delegates to
/// [LikeBlurredImage] rather than a bare `Image.network` so the request
/// carries the session Bearer token — `/api/users/profile-images/...` is
/// authenticated, and an anonymous fetch 401s into the fallback glyph.
class LikeCardAvatar extends StatelessWidget {
  final LikeProfileImage? image;
  final double size;
  const LikeCardAvatar({super.key, required this.image, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final photo = image;
    final url = photo?.url;
    final hasImage = url != null && url.isNotEmpty;
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
          child: !hasImage
              ? const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: QeranColors.wine,
                )
              : LikeBlurredImage(
                  url: url,
                  blur: photo?.isBlurred ?? false,
                  blurredUrl: photo?.blurredUrl,
                  blurredThumbnailUrl: photo?.blurredThumbnailUrl,
                  preferThumbnail: true,
                  size: null,
                  shape: BoxShape.circle,
                ),
        ),
      ),
    );
  }
}

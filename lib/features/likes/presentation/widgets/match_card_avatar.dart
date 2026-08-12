import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import 'like_blurred_image.dart';

/// Matches-tab avatar: a gold-hairline ring around a wine-tinted disc.
///
/// Mirrors [LikeCardAvatar] (the Sent/Received treatment) so every tab
/// shares one avatar language — but keeps [LikeBlurredImage]'s
/// authenticated fetch for the protected `/profile-images` URLs.
///
/// * **No photo** → a wine person glyph on a soft wine disc (never the
///   cold light-grey fallback).
/// * **Hidden photo** (`blur == true`) → the blurred image sits under a
///   dark-wine frost so a real photo reads as an intentional wine circle
///   instead of surfacing its raw (often off-tinted) colours.
class MatchCardAvatar extends StatelessWidget {
  final String? url;
  final bool blur;
  final double size;
  final bool blockImageBytes;

  const MatchCardAvatar({
    super.key,
    required this.url,
    required this.blur,
    this.size = 64,
    this.blockImageBytes = false,
  });

  @override
  Widget build(BuildContext context) {
    final u = url;
    final hasImage = u != null && u.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.5),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s2),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base disc. Under a HIDDEN photo it's a SOLID deep wine so no
            // white/green shows through the frost; the empty + clear-photo
            // states keep the soft wine06 tint (matches Sent/Received).
            ColoredBox(
              color: hasImage && blur ? QeranColors.wine : QeranColors.wine06,
            ),
            if (hasImage)
              LikeBlurredImage(
                url: u,
                blur: blur,
                size: null,
                shape: BoxShape.circle,
                blockImageBytes: blockImageBytes,
              )
            else
              Center(
                child: Icon(
                  Icons.person_rounded,
                  size: size * 0.5,
                  color: QeranColors.wine,
                ),
              ),
            // Strong wine frost over a hidden real photo — reads as a solid
            // wine-tinted frosted circle, never the photo's raw (green/grey)
            // tint. Sits over the solid base so the result is fully opaque.
            if (hasImage && blur) const ColoredBox(color: QeranColors.wine80),
          ],
        ),
      ),
    );
  }
}

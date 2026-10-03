import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_page_indicator.dart';
import '../../../domain/entities/community_media.dart';
import '../../formatting/video_duration.dart';
import '../community_network_image.dart';
import 'media_geometry.dart';

/// A video post's frame before playback (A9; BA-B1–B3 in the feed, BA-C1–C3
/// on the post screen). The frame takes the video's own ratio clamped between
/// 4:5 and 16:9 (16:9 without a size); the poster is contained in it on wine,
/// never cropped, so a vertical video gets wine bars at its sides. A wine
/// gradient over the lower part, the gold play disc, and the length pill sit
/// on the frame. The poster is a signed link: it loads without our token.
/// Playback arrives in sub-step 11 through [onPlay].
class PostVideoTile extends StatelessWidget {
  const PostVideoTile({super.key, required this.video, this.onPlay});

  final CommunityVideo video;
  final VoidCallback? onPlay;

  /// The share of the frame, from the bottom, the gradient covers.
  static const double _gradientShare = 0.55;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
      child: ClipRRect(
        borderRadius: QeranRadii.controlR,
        child: AspectRatio(
          aspectRatio: clampedAspect(video.width, video.height),
          child: ColoredBox(
            color: QeranColors.wine,
            child: Stack(fit: StackFit.expand, children: _layers()),
          ),
        ),
      ),
    );
  }

  /// The poster, contained; the gradient; the play disc; the duration.
  List<Widget> _layers() {
    final poster = video.posterUrl?.trim() ?? '';
    return [
      if (poster.isNotEmpty)
        CommunityNetworkImage(
          poster,
          fit: BoxFit.contain,
          placeholder: const SizedBox.shrink(),
          fallback: const SizedBox.shrink(),
        ),
      const _BottomGradient(share: _gradientShare),
      Center(child: _PlayDisc(onTap: onPlay)),
      if (video.duration > Duration.zero)
        PositionedDirectional(
          bottom: QeranSpacing.s12,
          start: QeranSpacing.s12,
          child: QeranOverlayPill(formatVideoDuration(video.duration)),
        ),
    ];
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: share,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                QeranColors.wine.withValues(alpha: 0),
                QeranColors.wine60,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold play disc in the middle of the frame.
class _PlayDisc extends StatelessWidget {
  const _PlayDisc({required this.onTap});

  final VoidCallback? onTap;

  static const double _size = 60;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(
          color: QeranColors.gold,
          shape: BoxShape.circle,
          boxShadow: QeranShadows.e3,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 34,
          color: QeranColors.wine,
        ),
      ),
    );
  }
}

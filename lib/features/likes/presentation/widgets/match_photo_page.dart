import 'package:flutter/material.dart';

import '../../domain/entities/match_image.dart';
import 'like_blurred_image.dart';

/// One page of [MatchPhotoPager] — the photo, and the pinch-zoom the surface it
/// replaces already offered.
///
/// [InteractiveViewer] stays mounted at all times. It shares the horizontal
/// drag with the pager rather than stealing it: at rest the image is
/// `constrained`, so there is nothing to pan and the swipe reaches the pager;
/// zoomed in, panning the image is what the member wants and the pager waits.
///
/// Zoom is reset when the page is left ([isActive] goes false), so every page
/// is framed the same way each time it is reached.
///
/// The photo is built with **no access-policy arguments** — see
/// [MatchPhotoPager]. Those arguments are OR-ed with `PhotoViewScope`'s answer,
/// so supplying them here could only weaken it. The scope stays the one source,
/// resolved from context, and zoom does not touch that.
class MatchPhotoPage extends StatefulWidget {
  const MatchPhotoPage({
    super.key,
    required this.image,
    required this.isActive,
  });

  final MatchImage image;

  /// False once the member swipes away.
  final bool isActive;

  @override
  State<MatchPhotoPage> createState() => _MatchPhotoPageState();
}

class _MatchPhotoPageState extends State<MatchPhotoPage> {
  final TransformationController _transform = TransformationController();

  @override
  void didUpdateWidget(covariant MatchPhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 4,
      child: LikeBlurredImage(
        url: widget.image.url,
        // The SERVER's flag, handed to the scope to transform — the same
        // contract the grid tile uses. No policy arguments follow it: they
        // would be OR-ed in as "unprotected" and could only weaken what the
        // scope decides.
        blur: widget.image.isBlurred,
        blurredUrl: widget.image.blurredUrl,
        blurredThumbnailUrl: widget.image.blurredThumbnailUrl,
        size: null,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.zero,
        // contain, never cover: the point is to see the whole photo.
        fit: BoxFit.contain,
      ),
    );
  }
}

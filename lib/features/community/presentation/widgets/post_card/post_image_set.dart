import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_page_indicator.dart';
import '../../../domain/entities/community_media.dart';
import '../community_network_image.dart';
import 'media_geometry.dart';

/// A post's photos (A4–A7). One photo: a frame of its own ratio, clamped
/// between 4:5 and 16:9, no counter. Several: a square carousel with its
/// position pill at the top end and dots below — at most six, sliding with
/// the page (S2). [onTap] opens the viewer at the tapped photo.
class PostImageSet extends StatefulWidget {
  const PostImageSet({super.key, required this.images, this.onTap});

  /// In the matchmaker's order. Never empty.
  final List<CommunityImage> images;
  final ValueChanged<int>? onTap;

  @override
  State<PostImageSet> createState() => _PostImageSetState();
}

class _PostImageSetState extends State<PostImageSet> {
  int _index = 0;

  Widget _photo(int i) {
    final image = CommunityNetworkImage(widget.images[i].url);
    final onTap = widget.onTap;
    if (onTap == null) return image;
    return GestureDetector(onTap: () => onTap(i), child: image);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final single = images.length == 1;
    final frame = ClipRRect(
      borderRadius: QeranRadii.controlR,
      child: AspectRatio(
        aspectRatio: single
            ? clampedAspect(images.first.width, images.first.height)
            : 1,
        child: single ? _photo(0) : _carousel(),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
      child: single
          ? frame
          : Column(children: [frame, QeranSpacing.vs8, _dots()]),
    );
  }

  Widget _carousel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => _photo(i),
        ),
        PositionedDirectional(
          top: QeranSpacing.s12,
          end: QeranSpacing.s12,
          child: QeranPageCounter(
            index: _index + 1,
            total: widget.images.length,
          ),
        ),
      ],
    );
  }

  Widget _dots() {
    final window = dotWindow(widget.images.length, _index);
    return QeranPageDots(
      count: window.count,
      current: _index - window.start,
      tone: QeranPageDotsTone.paper,
    );
  }
}

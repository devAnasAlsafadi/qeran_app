import 'package:flutter/material.dart';

import '../../../domain/entities/community_media.dart';
import '../community_network_image.dart';

/// One photo in the viewer (G1–G3): its true ratio, as wide as the screen
/// and centred — contained when that would be too tall (S22). Pinch, or a
/// double tap at a point, zooms it; [onZoomed] says whether it is zoomed, so
/// the dots hide and the pages hold still.
class ViewerZoomableImage extends StatefulWidget {
  const ViewerZoomableImage({
    super.key,
    required this.image,
    required this.onZoomed,
  });

  final CommunityImage image;
  final ValueChanged<bool> onZoomed;

  @override
  State<ViewerZoomableImage> createState() => _ViewerZoomableImageState();
}

class _ViewerZoomableImageState extends State<ViewerZoomableImage> {
  final _transform = TransformationController();
  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;

  static const double _doubleTapScale = 2.5;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_report);
  }

  void _report() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomed(zoomed);
  }

  /// In at the tapped point, or back out.
  void _toggleZoom() {
    if (_zoomed) {
      _transform.value = Matrix4.identity();
      return;
    }
    final at = _doubleTapAt;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -at.dx * (_doubleTapScale - 1),
        -at.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  double get _ratio {
    final (w, h) = (widget.image.width, widget.image.height);
    return w > 0 && h > 0 ? w / h : 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        panEnabled: _zoomed,
        maxScale: 4,
        child: Center(
          child: AspectRatio(
            aspectRatio: _ratio,
            child: CommunityNetworkImage(
              widget.image.url,
              fit: BoxFit.contain,
              onWine: true,
              placeholder: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

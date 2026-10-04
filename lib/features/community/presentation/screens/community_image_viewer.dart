import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/theme/qeran_system_bars.dart';
import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_page_indicator.dart';
import '../../domain/entities/community_media.dart';
import '../widgets/viewer/viewer_top_bar.dart';
import '../widgets/viewer/viewer_zoomable_image.dart';

/// A post's photos full screen (G1–G3), on wine: swipe between them, pinch
/// or double-tap to zoom, swipe down to close. The counter and the dots
/// say where you are; the dots hide while a photo is zoomed, and the pages
/// hold still so a zoomed photo can be moved.
class CommunityImageViewer extends StatefulWidget {
  const CommunityImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<CommunityImage> images;
  final int initialIndex;

  @override
  State<CommunityImageViewer> createState() => _CommunityImageViewerState();
}

class _CommunityImageViewerState extends State<CommunityImageViewer> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  /// How far a swipe down has pulled the photo.
  double _pull = 0;

  /// A pull past this, or a quick flick, closes the viewer.
  static const double _closeAt = 120;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _pullEnd(DragEndDetails details) {
    if (_pull > _closeAt || (details.primaryVelocity ?? 0) > 800) {
      return _close();
    }
    setState(() => _pull = 0);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: QeranSystemBars.lightIcons,
      child: Scaffold(
        backgroundColor: QeranColors.wine,
        body: Stack(
          children: [
            Positioned.fill(child: _pager()),
            // Every layer positioned: the stack then fills the screen.
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: ViewerTopBar(
                onClose: _close,
                counter: count > 1 ? '${_index + 1} / $count' : null,
              ),
            ),
            if (count > 1 && !_zoomed) _dots(count),
          ],
        ),
      ),
    );
  }

  Widget _dots(int count) => PositionedDirectional(
    start: 0,
    end: 0,
    bottom: MediaQuery.paddingOf(context).bottom + 28,
    child: QeranPageDots(
      count: count,
      current: _index,
      tone: QeranPageDotsTone.wine,
    ),
  );

  /// The photos, a page each; pulled down as one while none is zoomed.
  Widget _pager() => GestureDetector(
    onVerticalDragUpdate: _zoomed
        ? null
        : (d) => setState(() => _pull = (_pull + d.delta.dy).clamp(0, 400)),
    onVerticalDragEnd: _zoomed ? null : _pullEnd,
    child: Transform.translate(
      offset: Offset(0, _pull),
      child: PageView.builder(
        controller: _pages,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => ViewerZoomableImage(
          image: widget.images[i],
          onZoomed: (zoomed) => setState(() => _zoomed = zoomed),
        ),
      ),
    ),
  );
}

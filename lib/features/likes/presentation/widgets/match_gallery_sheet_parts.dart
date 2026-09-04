part of 'match_gallery_sheet.dart';

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

/// One photo in the gallery grid.
///
/// Tappable exactly when the photo is already being shown CLEAR. A blurred
/// tile (locked, or the window spent) ignores taps entirely rather than
/// offering a zoom of a redacted image — and the pager it opens applies the
/// same policy again, per page, since a swipe reaches photos no tap gated.
class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.image, required this.onOpen});

  final MatchImage image;

  /// Opens the pager on this photo. Only wired for a tile that is already
  /// clear — see [build].
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final access = PhotoViewScope.maybeOf(context);
    final blurred = access?.effectiveBlur(image.isBlurred) ?? image.isBlurred;
    final tile = LikeBlurredImage(
      url: image.url,
      blur: image.isBlurred,
      blurredUrl: image.blurredUrl,
      blurredThumbnailUrl: image.blurredThumbnailUrl,
      size: null,
      shape: BoxShape.rectangle,
      borderRadius: QeranRadii.cardR,
    );
    if (blurred || image.url.isEmpty) return tile;
    // No Hero: the pager is a layer, not a route, so there is no flight to
    // stage — the sheet cross-fades to it instead.
    return GestureDetector(onTap: onOpen, child: tile);
  }
}

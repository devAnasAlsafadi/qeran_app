part of 'match_gallery_sheet.dart';

/// The resting surface of the sheet: the title row, the report action and the
/// grid of tiles, with the access overlay stacked on top of them.
///
/// A widget rather than a method on the sheet's state because the sheet is
/// rebuilt on every tick of the open/close resize; keeping it separate says
/// plainly that nothing here holds state worth losing.
class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.images,
    required this.targetUserId,
    required this.scrollController,
    required this.onOpen,
  });

  final List<MatchImage> images;
  final String? targetUserId;
  final ScrollController scrollController;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
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
          _header(context),
          const SizedBox(height: QeranSpacing.s12),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _tiles()),
                const PhotoViewOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final id = targetUserId;
    return Row(
      children: [
        // Balances the report action opposite it so the title stays centred.
        const SizedBox(width: 40),
        Expanded(
          child: Text(
            LocaleKeys.likes_matches_gallery_title.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.title.copyWith(color: QeranColors.wine),
          ),
        ),
        SizedBox(
          width: 40,
          child: id == null
              ? null
              : IconButton(
                  tooltip: LocaleKeys.report_title.t(context),
                  icon: const Icon(
                    Icons.flag_outlined,
                    color: QeranColors.wine,
                    size: 22,
                  ),
                  onPressed: () => showReportSheet(context, targetUserId: id),
                ),
        ),
      ],
    );
  }

  Widget _tiles() {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: QeranSpacing.s8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: QeranSpacing.s12,
        crossAxisSpacing: QeranSpacing.s12,
        childAspectRatio: 0.85,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) =>
          _GalleryTile(image: images[index], onOpen: () => onOpen(index)),
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

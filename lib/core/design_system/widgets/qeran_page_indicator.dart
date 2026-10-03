import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_typography.dart';

/// Position readouts for a photo pager, extracted from `ProfileHeaderGallery`
/// so every swipeable gallery in either app reports its position the same way.
///
/// They are a pair by convention, not by construction: the pill answers "which
/// one of how many" precisely, the dots answer "how far along" at a glance, and
/// a surface may mount either alone.

/// A small dark pill over imagery — a photo's position, a video's length.
/// Dark-overlay ground so it stays legible over any photo. Its text is laid
/// out left to right in every language: it is figures, not prose.
class QeranOverlayPill extends StatelessWidget {
  const QeranOverlayPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: QeranColors.overlayTintDark,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        text,
        // Left to the ambient direction, Arabic reverses figures around a
        // separator: the bidi algorithm treats `/` between two numbers as
        // RTL, so `1 / 5` renders as `5 / 1`.
        textDirection: TextDirection.ltr,
        style: QeranTypography.caption.copyWith(color: QeranColors.paper),
      ),
    );
  }
}

/// The `1 / N` pill.
class QeranPageCounter extends StatelessWidget {
  const QeranPageCounter({
    super.key,
    required this.index,
    required this.total,
  });

  /// One-based position of the visible page.
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => QeranOverlayPill('$index / $total');
}

/// Where the dots sit: over a photo, or on a card's paper below it.
enum QeranPageDotsTone {
  /// Gold 8 dp active dot, cream-surface 6 dp dots — legible over imagery.
  photo,

  /// A gold-deep 18 × 6 dp pill for the active dot, wine-20 6 dp dots —
  /// legible on paper, where cream dots would vanish (a Community post).
  paper,
}

/// Page-position dots. Animates between states so a page swipe reads as a
/// smooth shift rather than a hard cut.
///
/// Symmetric by design, so it needs no mirroring: [current] is the page index
/// the pager reports, and the row's own direction places the dots. Never flip
/// it by hand for RTL — `PageView` has already done that.
class QeranPageDots extends StatelessWidget {
  const QeranPageDots({
    super.key,
    required this.count,
    required this.current,
    this.tone = QeranPageDotsTone.photo,
  });

  final int count;
  final QeranPageDotsTone tone;

  /// Zero-based index of the visible page.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        final paper = tone == QeranPageDotsTone.paper;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: isActive ? (paper ? 18 : 8) : 6,
          height: isActive && !paper ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.pill,
            color: switch ((paper, isActive)) {
              (false, true) => QeranColors.gold,
              (false, false) => QeranColors.creamSurface,
              (true, true) => QeranColors.goldDeep,
              (true, false) => QeranColors.wine20,
            },
          ),
        );
      }),
    );
  }
}

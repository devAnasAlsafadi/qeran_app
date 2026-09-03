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

/// The `1 / N` pill. Dark-overlay ground so it stays legible over any photo.
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: QeranColors.overlayTintDark,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        '$index / $total',
        // A ratio, not prose — it reads the same way in every language. Left
        // to the ambient direction, Arabic reverses it: the bidi algorithm
        // treats the separator between two numbers as RTL, so `1 / 5` renders
        // as `5 / 1` and the member is told they are on photo 5 of 1.
        textDirection: TextDirection.ltr,
        style: QeranTypography.caption.copyWith(color: QeranColors.paper),
      ),
    );
  }
}

/// Page-position dots. Gold + 8 dp for the active dot, cream-surface + 6 dp for
/// the rest. Animates between states so a page swipe reads as a smooth shift
/// rather than a hard cut.
///
/// Symmetric by design, so it needs no mirroring: [current] is the page index
/// the pager reports, and the row's own direction places the dots. Never flip
/// it by hand for RTL — `PageView` has already done that.
class QeranPageDots extends StatelessWidget {
  const QeranPageDots({
    super.key,
    required this.count,
    required this.current,
  });

  final int count;

  /// Zero-based index of the visible page.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? QeranColors.gold : QeranColors.creamSurface,
          ),
        );
      }),
    );
  }
}

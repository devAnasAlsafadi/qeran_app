import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_typography.dart';

/// A small gold pill carrying an unread count, for the notifications bell in
/// both shells.
///
/// Gold on wine, never red: an unread notification is an invitation, not a
/// fault, and red is reserved for danger in this identity.
///
/// The paper ring is what keeps it readable wherever it lands — the user's
/// bell sits on a photo, the matchmaker's on the app bar, and without a ring
/// the pill dissolves into whichever one it is over.
class QeranCountBadge extends StatelessWidget {
  const QeranCountBadge({
    super.key,
    required this.count,
    this.cap = 99,
    this.color = QeranColors.gold,
  });

  final int count;

  /// Counts above this render as `<cap>+`. A bell badge is a nudge, not a
  /// figure worth reading precisely, and an unbounded number would widen the
  /// pill until it overhangs the icon it belongs to.
  final int cap;

  final Color color;

  @override
  Widget build(BuildContext context) {
    // A pill, not a circle: three glyphs ("99+") cannot sit in a circle
    // without either clipping or inflating it well past the icon.
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: QeranColors.paper, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        // Kept as digits + '+' in both locales. The app renders Western digits
        // throughout, and the nav's own badge has shipped this shape already.
        count > cap ? '$cap+' : '$count',
        style: QeranTypography.caption.copyWith(
          color: QeranColors.wine,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.1,
        ),
      ),
    );
  }
}

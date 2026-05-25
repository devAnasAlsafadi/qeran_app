import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

enum QeranChipVariant { score, meta, inside, interest, status }

/// All pill / tag visuals in the app go through this widget.
class QeranChip extends StatelessWidget {
  const QeranChip({
    super.key,
    required this.label,
    this.variant = QeranChipVariant.meta,
    this.icon,
    this.statusColor,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final QeranChipVariant variant;
  final IconData? icon;

  /// Required for [QeranChipVariant.status]. Ignored otherwise.
  final Color? statusColor;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(variant, statusColor);
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : QeranSpacing.chipPad;
    final style = (compact ? QeranTypography.caption : QeranTypography.label)
        .copyWith(color: spec.fg);

    final body = Padding(
      padding: pad,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: spec.fg),
            QeranSpacing.hs4,
          ],
          Text(label, style: style),
        ],
      ),
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: QeranRadii.pill,
        border: spec.border == null
            ? null
            : Border.all(color: spec.border!, width: 1),
      ),
      child: body,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.pill,
      child: InkWell(
        borderRadius: QeranRadii.pill,
        onTap: onTap,
        child: decorated,
      ),
    );
  }

  static _ChipSpec _spec(QeranChipVariant v, Color? statusColor) =>
      switch (v) {
        QeranChipVariant.score => const _ChipSpec(
            bg: QeranColors.wine,
            fg: QeranColors.paper,
          ),
        QeranChipVariant.meta => const _ChipSpec(
            bg: QeranColors.creamSurface,
            fg: QeranColors.wine,
          ),
        QeranChipVariant.inside => const _ChipSpec(
            bg: QeranColors.paper,
            fg: QeranColors.wine,
            border: QeranColors.wine12,
          ),
        QeranChipVariant.interest => const _ChipSpec(
            bg: QeranColors.gold12,
            fg: QeranColors.wine,
            border: QeranColors.gold40,
          ),
        QeranChipVariant.status => _ChipSpec(
            bg: (statusColor ?? QeranColors.wine).withValues(alpha: 0.12),
            fg: statusColor ?? QeranColors.wine,
          ),
      };
}

class _ChipSpec {
  const _ChipSpec({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
}

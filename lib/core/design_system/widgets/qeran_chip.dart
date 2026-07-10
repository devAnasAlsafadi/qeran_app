import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

enum QeranChipVariant { score, meta, inside, interest, plan, status, glass }

/// All pill / tag visuals in the app go through this widget.
class QeranChip extends StatelessWidget {
  const QeranChip({
    super.key,
    required this.label,
    this.variant = QeranChipVariant.meta,
    this.icon,
    this.iconColor,
    this.statusColor,
    this.compact = false,
    this.onTap,
    this.maxWidth,
  });

  final String label;
  final QeranChipVariant variant;
  final IconData? icon;

  /// When set, the chip is bounded to this width and its label ellipsizes on
  /// one line instead of growing/overflowing. Opt-in — unconstrained chips
  /// (the default) keep sizing to their content, which is required inside
  /// horizontal scrollables where a flex label would throw.
  final double? maxWidth;

  /// Overrides the icon colour (defaults to the variant's foreground). Used by
  /// [QeranChipVariant.glass] to carry a gold icon over paper text.
  final Color? iconColor;

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

    final labelText = Text(
      label,
      style: style,
      maxLines: 1,
      overflow: maxWidth == null ? TextOverflow.clip : TextOverflow.ellipsis,
      softWrap: false,
    );
    final body = Padding(
      padding: pad,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: iconColor ?? spec.fg),
            QeranSpacing.hs4,
          ],
          // Flexible only when bounded — an unconstrained flex label would
          // throw inside a horizontal scrollable.
          maxWidth == null ? labelText : Flexible(child: labelText),
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

    final sized = maxWidth == null
        ? decorated
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: decorated,
          );

    if (onTap == null) return sized;

    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.pill,
      child: InkWell(
        borderRadius: QeranRadii.pill,
        onTap: onTap,
        child: sized,
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
        // Subscription-plan chip — the gold-tier identity with legible
        // gold-deep text (a step darker than [interest]'s wine text).
        QeranChipVariant.plan => const _ChipSpec(
            bg: QeranColors.gold12,
            fg: QeranColors.goldDeep,
            border: QeranColors.gold40,
          ),
        QeranChipVariant.status => _ChipSpec(
            bg: (statusColor ?? QeranColors.wine).withValues(alpha: 0.12),
            fg: statusColor ?? QeranColors.wine,
          ),
        // Translucent "glass" pill for chips riding over imagery / a dark
        // scrim — paper text on a frosted-white fill with a hairline rim.
        QeranChipVariant.glass => _ChipSpec(
            bg: QeranColors.paper.withValues(alpha: 0.13),
            fg: QeranColors.paper,
            border: QeranColors.paper.withValues(alpha: 0.18),
          ),
      };
}

class _ChipSpec {
  const _ChipSpec({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
}

import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// Brand dual-thumb range control: a `--qeran-wine-08` base track with a
/// `--qeran-gold` active segment + gold thumbs, and a numeric-LTR value label
/// ("20 – 45") in gold-deep beside the section [label]. Reusable for any range
/// facet (age / height / weight). Emits integer min/max on drag.
class QeranRangeSlider extends StatelessWidget {
  const QeranRangeSlider({
    super.key,
    required this.label,
    required this.min,
    required this.max,
    required this.start,
    required this.end,
    required this.onChanged,
    this.unit,
  });

  final String label;
  final int min;
  final int max;
  final int start;
  final int end;
  final void Function(int start, int end) onChanged;

  /// Optional unit appended to the value label (e.g. "سنة", "cm").
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final lo = min.toDouble();
    final hi = max.toDouble();
    final values = RangeValues(
      start.toDouble().clamp(lo, hi),
      end.toDouble().clamp(lo, hi),
    );
    final u = (unit != null && unit!.isNotEmpty) ? ' ${unit!}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: QeranTypography.subtitle)),
            QeranSpacing.hs8,
            Text(
              '$start – $end$u',
              // Numeric-LTR — the range reads left-to-right in any locale.
              textDirection: TextDirection.ltr,
              style: QeranTypography.label.copyWith(
                color: QeranColors.goldDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: QeranColors.gold,
            inactiveTrackColor: QeranColors.wine08,
            thumbColor: QeranColors.gold,
            overlayColor: QeranColors.gold.withValues(alpha: 0.14),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              pressedElevation: 2,
            ),
            showValueIndicator: ShowValueIndicator.never,
            trackHeight: 4,
          ),
          child: RangeSlider(
            values: values,
            min: lo,
            max: hi,
            divisions: (hi - lo).toInt().clamp(1, 1000),
            onChanged: (v) => onChanged(v.start.round(), v.end.round()),
          ),
        ),
      ],
    );
  }
}

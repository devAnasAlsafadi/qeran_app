import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// A decorative back-and-forth conversation filling the frame behind the
/// matchmaker glass card: incoming bubbles (muted mauve wine) on the start edge,
/// outgoing bubbles (soft gold, with a delivered tick + timestamp) on the end
/// edge. The bubble shapes read clearly as a chat; only the inner content bars
/// are blurred, so there is no word to read. The frosted card floats over it.
class OnboardingChatBackdrop extends StatelessWidget {
  const OnboardingChatBackdrop({super.key});

  // (outgoing, widthFactor, twoLines)
  static const List<(bool, double, bool)> _messages = [
    (false, 0.60, true),
    (true, 0.66, true),
    (false, 0.52, false),
    (true, 0.70, true),
    (false, 0.58, true),
    (true, 0.54, false),
    (false, 0.64, true),
    (true, 0.50, false),
    (false, 0.50, false),
  ];

  @override
  Widget build(BuildContext context) {
    // Recessed behind the card using baked alpha values. Avoiding a full-frame
    // Opacity + ImageFiltered pair removes two offscreen layers while the
    // abstract bars remain intentionally unreadable.
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s12,
          vertical: QeranSpacing.s16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final (outgoing, width, twoLines) in _messages)
              _Bubble(
                outgoing: outgoing,
                widthFactor: width,
                twoLines: twoLines,
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool outgoing;
  final double widthFactor;
  final bool twoLines;

  const _Bubble({
    required this.outgoing,
    required this.widthFactor,
    required this.twoLines,
  });

  @override
  Widget build(BuildContext context) {
    final align = outgoing
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    // Incoming uses a mauve wine ink (clearly lighter than the wine canvas so
    // the bubble reads); outgoing uses soft gold.
    final bubbleColor = outgoing
        ? QeranColors.gold20
        : QeranColors.inkBody.withValues(alpha: 0.48);
    final barColor = outgoing
        ? QeranColors.wine.withValues(alpha: 0.30)
        : QeranColors.paper.withValues(alpha: 0.36);
    final metaColor = outgoing
        ? QeranColors.wine.withValues(alpha: 0.25)
        : QeranColors.paper.withValues(alpha: 0.25);
    return Align(
      alignment: align,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: align,
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: QeranRadii.controlR,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Bar(color: barColor, widthFactor: 0.92, align: align),
                  if (twoLines) ...[
                    QeranSpacing.vs4,
                    _Bar(color: barColor, widthFactor: 0.60, align: align),
                  ],
                ],
              ),
              QeranSpacing.vs4,
              _MetaRow(outgoing: outgoing, color: metaColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny timestamp bar and, for sent bubbles, a delivered tick.
class _MetaRow extends StatelessWidget {
  final bool outgoing;
  final Color color;

  const _MetaRow({required this.outgoing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: outgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: QeranRadii.pill,
          ),
        ),
        if (outgoing) ...[
          QeranSpacing.hs4,
          const Icon(
            Icons.done_all_rounded,
            size: 11,
            color: QeranColors.goldDeep,
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final Color color;
  final double widthFactor;
  final AlignmentGeometry align;

  const _Bar({
    required this.color,
    required this.widthFactor,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: align,
      child: Container(
        height: 6,
        decoration: BoxDecoration(color: color, borderRadius: QeranRadii.pill),
      ),
    );
  }
}

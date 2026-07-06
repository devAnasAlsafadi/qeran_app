import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The journey's destination: two interlocking gold rings (a marriage motif)
/// over a soft gold glow, with the "marriage" label beneath. Closes the roadmap
/// timeline.
class OnboardingMarriageDestination extends StatelessWidget {
  const OnboardingMarriageDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 94,
          height: 56,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        QeranColors.gold.withValues(alpha: 0.30),
                        QeranColors.gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              const Center(
                child: SizedBox(
                  width: 88,
                  height: 53,
                  child: CustomPaint(painter: _MarriageRingsPainter()),
                ),
              ),
            ],
          ),
        ),
        QeranSpacing.vs4,
        Text(
          LocaleKeys.onboarding_roadmap_marriage.t(context),
          style: QeranTypography.label.copyWith(
            color: QeranColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MarriageRingsPainter extends CustomPainter {
  const _MarriageRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinates map from the design's 100×60 viewbox.
    double sx(double x) => x / 100 * size.width;
    double sy(double y) => y / 60 * size.height;

    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [QeranColors.goldLight, QeranColors.gold, QeranColors.goldDeep],
    ).createShader(Offset.zero & size);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sx(6)
      ..shader = shader;
    final r = sx(20);
    canvas.drawCircle(Offset(sx(39), sy(33)), r, ring);
    canvas.drawCircle(Offset(sx(62), sy(33)), r, ring);

    // A small four-point sparkle above the rings.
    final star = Path()
      ..addPolygon(<Offset>[
        Offset(sx(78), sy(6)),
        Offset(sx(80.2), sy(11.4)),
        Offset(sx(85.6), sy(13.6)),
        Offset(sx(80.2), sy(15.8)),
        Offset(sx(78), sy(21.2)),
        Offset(sx(75.8), sy(15.8)),
        Offset(sx(70.4), sy(13.6)),
        Offset(sx(75.8), sy(11.4)),
      ], true);
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.fill
        ..color = QeranColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(covariant _MarriageRingsPainter oldDelegate) => false;
}

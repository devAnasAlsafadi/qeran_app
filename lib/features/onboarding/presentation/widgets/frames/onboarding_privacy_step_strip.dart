import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The secure-unblur flow, as a horizontal 5-step strip riding the top of the
/// essence dome: blurred → interest → request → consent → revealed. A wine
/// hairline base line runs behind the nodes with a slow gold highlight sweeping
/// along it (direction-agnostic via `PositionedDirectional`).
class OnboardingPrivacyStepStrip extends StatefulWidget {
  const OnboardingPrivacyStepStrip({super.key});

  static const double _nodeSize = 26;

  @override
  State<OnboardingPrivacyStepStrip> createState() =>
      _OnboardingPrivacyStepStripState();
}

class _OnboardingPrivacyStepStripState extends State<OnboardingPrivacyStepStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QeranMotion.shimmer,
  )..repeat();
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: QeranCurves.shimmer,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String)>[
      (Icons.blur_on_rounded, LocaleKeys.onboarding_essence_step_blurred.t(context)),
      (Icons.favorite_rounded, LocaleKeys.onboarding_essence_step_interest.t(context)),
      (Icons.swap_horiz_rounded, LocaleKeys.onboarding_essence_step_request.t(context)),
      (Icons.handshake_rounded, LocaleKeys.onboarding_essence_step_consent.t(context)),
      (Icons.visibility_rounded, LocaleKeys.onboarding_essence_step_revealed.t(context)),
    ];
    const node = OnboardingPrivacyStepStrip._nodeSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        final nodeWidth = constraints.maxWidth / steps.length;
        final connectorW = constraints.maxWidth - nodeWidth;
        // The Row sizes the Stack to its tallest (2-line) cell — no fixed
        // height, so labels never overflow in either language.
        return Stack(
          children: [
            // Wine hairline base line, between the first and last node centres.
            PositionedDirectional(
              start: nodeWidth / 2,
              end: nodeWidth / 2,
              top: node / 2 - 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: QeranColors.wine12,
                  borderRadius: QeranRadii.pill,
                ),
                child: SizedBox(height: 2),
              ),
            ),
            PositionedDirectional(
              start: nodeWidth / 2,
              top: node / 2 - 1,
              child: _GoldTrack(width: connectorW, t: _t),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (icon, label) in steps)
                  SizedBox(
                    width: nodeWidth,
                    child: _Step(icon: icon, label: label),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A short gold highlight that slides along the connector line and repeats.
class _GoldTrack extends StatelessWidget {
  final double width;
  final Animation<double> t;

  const _GoldTrack({required this.width, required this.t});

  @override
  Widget build(BuildContext context) {
    final segW = width * 0.4;
    return ClipRect(
      child: SizedBox(
        width: width,
        height: 2,
        child: AnimatedBuilder(
          animation: t,
          builder: (context, child) {
            final dx = -segW + (width + segW) * t.value;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Container(
            width: segW,
            height: 2,
            decoration: const BoxDecoration(
              borderRadius: QeranRadii.pill,
              gradient: LinearGradient(
                colors: [
                  QeranColors.gold08,
                  QeranColors.gold,
                  QeranColors.gold08,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Step({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: OnboardingPrivacyStepStrip._nodeSize,
          height: OnboardingPrivacyStepStrip._nodeSize,
          decoration: BoxDecoration(
            color: QeranColors.gold12,
            shape: BoxShape.circle,
            border: Border.all(color: QeranColors.gold40, width: 1.5),
            boxShadow: QeranShadows.e1,
          ),
          child: Icon(icon, size: 15, color: QeranColors.goldDeep),
        ),
        QeranSpacing.vs4,
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
        ),
      ],
    );
  }
}

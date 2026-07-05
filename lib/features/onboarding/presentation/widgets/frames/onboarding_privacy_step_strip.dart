import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The secure-unblur flow, as a horizontal 5-step strip:
/// blurred → interest → request → consent → revealed. A hairline connector runs
/// behind the nodes (direction-agnostic via `PositionedDirectional`).
class OnboardingPrivacyStepStrip extends StatelessWidget {
  const OnboardingPrivacyStepStrip({super.key});

  static const double _nodeSize = 34;

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String)>[
      (Icons.blur_on_rounded, LocaleKeys.onboarding_essence_step_blurred.t(context)),
      (Icons.favorite_rounded, LocaleKeys.onboarding_essence_step_interest.t(context)),
      (Icons.swap_horiz_rounded, LocaleKeys.onboarding_essence_step_request.t(context)),
      (Icons.handshake_rounded, LocaleKeys.onboarding_essence_step_consent.t(context)),
      (Icons.visibility_rounded, LocaleKeys.onboarding_essence_step_revealed.t(context)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final nodeWidth = constraints.maxWidth / steps.length;
        return SizedBox(
          height: 74,
          child: Stack(
            children: [
              // Connector behind the nodes — between the first and last centres.
              PositionedDirectional(
                start: nodeWidth / 2,
                end: nodeWidth / 2,
                top: _nodeSize / 2,
                child: Container(height: 1.5, color: QeranColors.gold40),
              ),
              Row(
                children: [
                  for (final (icon, label) in steps)
                    SizedBox(
                      width: nodeWidth,
                      child: _Step(icon: icon, label: label),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
            color: QeranColors.creamSurface,
            shape: BoxShape.circle,
            border: Border.all(color: QeranColors.gold40, width: 1.2),
          ),
          child: Icon(icon, size: 16, color: QeranColors.wine),
        ),
        QeranSpacing.vs8,
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: QeranTypography.caption.copyWith(color: QeranColors.paper),
        ),
      ],
    );
  }
}

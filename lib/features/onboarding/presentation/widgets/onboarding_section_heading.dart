import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// A content-frame section heading: a short gold accent bar followed by the
/// section title. Shared across onboarding frames so every heading reads
/// identically.
///
/// Gold on the wine canvas — the frames carry no paper surface, so the title
/// takes the brand accent rather than wine ink, which would be invisible here.
class OnboardingSectionHeading extends StatelessWidget {
  final String title;

  const OnboardingSectionHeading({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 21,
          decoration: const BoxDecoration(
            color: QeranColors.gold,
            borderRadius: QeranRadii.xsR,
          ),
        ),
        QeranSpacing.hs8,
        Expanded(
          child: Text(
            title,
            style: QeranTypography.title.copyWith(color: QeranColors.gold),
          ),
        ),
      ],
    );
  }
}

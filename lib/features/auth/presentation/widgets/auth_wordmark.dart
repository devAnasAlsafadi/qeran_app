import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The auth brand lockup shown inside the wine hero: the Arabic wordmark
/// «قِران» in gold above the Latin "Qeran" in paper, with the shared brand
/// tagline beneath.
///
/// The two wordmarks are a fixed brand mark, NOT localized copy (they read
/// the same in every locale). Only the tagline is localized — it reuses the
/// onboarding brand tagline key so auth and onboarding stay in sync.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'قِران',
          textAlign: TextAlign.center,
          style: QeranTypography.headline.copyWith(color: QeranColors.gold),
        ),
        QeranSpacing.vs4,
        Text(
          'Qeran',
          textAlign: TextAlign.center,
          style: QeranTypography.displayLg.copyWith(
            color: QeranColors.paper,
            letterSpacing: 0.8,
          ),
        ),
        QeranSpacing.vs12,
        Text(
          LocaleKeys.onboarding_splash_tagline.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.body.copyWith(color: QeranColors.gold80),
        ),
      ],
    );
  }
}

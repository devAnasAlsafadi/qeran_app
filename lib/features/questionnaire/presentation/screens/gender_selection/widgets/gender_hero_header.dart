import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The gender screen's wine hero band — the onboarding family's
/// `wineLight → wine` gradient + a quiet gold [RingMotif], carrying the
/// language pill and the welcome + "choose your identity" heading. The cream
/// dome below (in the screen) surfaces out of it and holds the two cards, so
/// the top of the screen reads as composed brand space rather than empty white.
class GenderHeroHeader extends StatelessWidget {
  const GenderHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: RingMotif(
                  color: QeranColors.gold,
                  opacity: 0.10,
                  size: 300,
                  ringCount: 3,
                  spacing: 22,
                ),
              ),
            ),
            Padding(
              // Extra top space seats the heading lower in the wine (anchored,
              // not floating high near the status bar).
              padding: const EdgeInsetsDirectional.fromSTEB(
                QeranSpacing.s20,
                QeranSpacing.s64,
                QeranSpacing.s20,
                QeranSpacing.s32,
              ),
              child: Column(
                children: [
                  Text(
                    LocaleKeys.questionnaire_welcome.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.displayLg.copyWith(
                      color: QeranColors.gold,
                    ),
                  ),
                  QeranSpacing.vs4,
                  Text(
                    LocaleKeys.questionnaire_choose_identity.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.displaySm.copyWith(
                      color: QeranColors.paper,
                    ),
                  ),
                  QeranSpacing.vs8,
                  Text(
                    LocaleKeys.questionnaire_identity_info.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.bodySm.copyWith(
                      color: QeranColors.gold60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

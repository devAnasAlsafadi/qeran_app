import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_sheen.dart';

/// The matchmaker (Huda) profile as a **glassmorphic** card: a wine gradient
/// backdrop frosted by a `BackdropFilter` blur plus a translucent cream veil
/// (the approved way to simulate the design's `saturate`). A subtle gold ring
/// motif adds depth; the content — avatar, name, verified badge, role — rides
/// on the frosted glass.
class OnboardingMatchmakerGlassCard extends StatelessWidget {
  const OnboardingMatchmakerGlassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: QeranRadii.panelR,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [QeranColors.wine, QeranColors.wineLight],
                ),
              ),
            ),
          ),
          const PositionedDirectional(
            top: -40,
            end: -30,
            child: RingMotif(
              color: QeranColors.gold,
              opacity: 0.16,
              size: 170,
              ringCount: 2,
              spacing: 20,
            ),
          ),
          // Frosted glass: blur the gradient behind + a cream veil for the tint.
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              color: QeranColors.paper.withValues(alpha: 0.68),
              padding: const EdgeInsets.all(QeranSpacing.s16),
              child: const _MatchmakerRow(),
            ),
          ),
          // A slow diagonal glint travelling across the glass.
          const Positioned.fill(child: OnboardingSheen()),
          // 1px gold rim-light — catches the eye along the card's edge.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: QeranRadii.panelR,
                  border: Border.all(color: QeranColors.gold40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchmakerRow extends StatelessWidget {
  const _MatchmakerRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [QeranColors.gold, QeranColors.goldDeep],
            ),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: QeranColors.wine,
            size: 28,
          ),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      LocaleKeys.onboarding_mediation_name.t(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: QeranTypography.subtitle.copyWith(
                        color: QeranColors.wine,
                      ),
                    ),
                  ),
                  QeranSpacing.hs8,
                  QeranChip(
                    icon: Icons.verified_rounded,
                    label: LocaleKeys.onboarding_mediation_verified.t(context),
                    variant: QeranChipVariant.interest,
                    compact: true,
                  ),
                ],
              ),
              QeranSpacing.vs4,
              Text(
                LocaleKeys.onboarding_mediation_role.t(context),
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

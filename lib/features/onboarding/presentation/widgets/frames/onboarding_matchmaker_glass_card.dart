import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_mediation_blocks.dart';

/// The matchmaker (Huda) as a **dark frosted glass** card: a wine tint over a
/// layered wine tint (which reads as frosted glass), a gold rim, and crisp
/// paper content on top — header, the mediation status
/// rows, and the "search with the matchmaker" CTA. [onSearch] advances the flow.
class OnboardingMatchmakerGlassCard extends StatelessWidget {
  final VoidCallback onSearch;

  const OnboardingMatchmakerGlassCard({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: QeranRadii.cardR,
      child: Stack(
        children: [
          // Baked translucent gradient keeps the glass character without a
          // live BackdropFilter over the full card on every raster frame.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    QeranColors.wine.withValues(alpha: 0.90),
                    QeranColors.wine.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(QeranSpacing.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                QeranSpacing.vs12,
                Container(
                  height: 1,
                  color: QeranColors.paper.withValues(alpha: 0.14),
                ),
                QeranSpacing.vs12,
                const OnboardingMediationBlocks(),
                QeranSpacing.vs12,
                QeranButton(
                  label: LocaleKeys.onboarding_mediation_search_cta.t(context),
                  leadingIcon: Icons.person_search_rounded,
                  size: QeranButtonSize.md,
                  onPressed: onSearch,
                ),
              ],
            ),
          ),
          // 1px gold rim catching the card's edge.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: QeranRadii.cardR,
                  border: Border.all(color: QeranColors.gold60),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: QeranColors.wine,
            border: Border.all(color: QeranColors.gold, width: 2),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: QeranColors.gold,
            size: 22,
          ),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.onboarding_mediation_name.t(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QeranTypography.subtitle.copyWith(
                  color: QeranColors.paper,
                ),
              ),
              Text(
                LocaleKeys.onboarding_mediation_role.t(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.paper.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        QeranSpacing.hs8,
        QeranChip(
          icon: Icons.verified_rounded,
          label: LocaleKeys.onboarding_mediation_verified.t(context),
          variant: QeranChipVariant.status,
          statusColor: QeranColors.gold,
          compact: true,
        ),
      ],
    );
  }
}

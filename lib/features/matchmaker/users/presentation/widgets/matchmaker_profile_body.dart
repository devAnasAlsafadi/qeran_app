import 'package:flutter/material.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../domain/entities/matchmaker_user_profile.dart';
import 'matchmaker_profile_hero.dart';
import 'matchmaker_profile_status_banner.dart';

/// Read surface for the matchmaker profile detail. Recomposes the user-side
/// profile presentation from the shared LEAF widgets ([MatchmakerProfileHero]
/// reuses the gallery + scrim + overlay chips; [PlacementRenderer] in its card
/// layout draws the نبذة + every section), so the شكل is unified without
/// touching any user-app file.
///
/// PV1 — the hero now overlays identity (name + age) and the above-image
/// fields on the photo. Email + profileStatus are matchmaker-only privileges;
/// they sit below the photo for now and fold into the نبذة sheet in PV2.
class MatchmakerProfileBody extends StatelessWidget {
  const MatchmakerProfileBody({super.key, required this.profile});

  final MatchmakerUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchmakerProfileHero(profile: profile),
        SoftScaleIn(
          duration: QeranMotion.gentle,
          beginScale: 0.97,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              MatchmakerProfileStatusBanner(status: profile.profileStatus),
              QeranSpacing.vs16,
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetaChips(gender: profile.gender, email: profile.email),
                    QeranSpacing.vs16,
                    // Same section-card composition as the user-side full
                    // profile: نبذة card + remaining sections, each a QeranCard.
                    PlacementRenderer(
                      placements: profile.placements,
                      asCards: true,
                      includeNarrative: true,
                    ),
                  ],
                ),
              ),
              QeranSpacing.vs32,
            ],
          ),
        ),
      ],
    );
  }
}

/// Interim presentation of the matchmaker-only fields (gender + email) as meta
/// chips — mirrors the user-side my-profile header. PV2 folds these into the
/// نبذة sheet (status chip + email row at the top of the main card).
class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.gender, required this.email});

  final String gender;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QeranSpacing.s12,
      runSpacing: QeranSpacing.s12,
      children: [
        if (gender.isNotEmpty)
          QeranChip(
            label: gender,
            variant: QeranChipVariant.meta,
            icon: Icons.person_outline_rounded,
          ),
        if (email.isNotEmpty)
          QeranChip(
            label: email,
            variant: QeranChipVariant.meta,
            icon: Icons.mail_outline_rounded,
          ),
      ],
    );
  }
}

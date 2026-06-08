import 'package:flutter/material.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../domain/entities/matchmaker_user_profile.dart';
import 'matchmaker_profile_hero.dart';
import 'matchmaker_profile_main_card.dart';

/// Read surface for the matchmaker profile detail — the SAME presentation as
/// the user-side full profile, recomposed from shared LEAF widgets so no
/// user-app file is touched:
///   hero overlay → main نبذة card (overlapping the photo, rounded-top:
///   status + email + نبذة + inside chips) → remaining sections as cards.
class MatchmakerProfileBody extends StatelessWidget {
  const MatchmakerProfileBody({super.key, required this.profile});

  final MatchmakerUserProfile profile;

  /// How far the content sheet slides up under the photo's bottom edge — the
  /// identity's photo-into-content layered look (matches the user side).
  static const double _sheetOverlap = QeranSpacing.s24;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchmakerProfileHero(profile: profile),
        Transform.translate(
          offset: const Offset(0, -_sheetOverlap),
          child: SoftScaleIn(
            duration: QeranMotion.gentle,
            beginScale: 0.97,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                MatchmakerProfileMainCard(profile: profile),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    QeranSpacing.s20,
                    QeranSpacing.s16,
                    QeranSpacing.s20,
                    0,
                  ),
                  // Remaining sections (about-partner / Q&A / interests) as
                  // their own cards — narrative is drawn in the main card above.
                  child: PlacementRenderer(
                    placements: profile.placements,
                    asCards: true,
                    includeNarrative: false,
                  ),
                ),
                QeranSpacing.vs32,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

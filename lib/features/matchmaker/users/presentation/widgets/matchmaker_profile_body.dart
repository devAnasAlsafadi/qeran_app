import 'package:flutter/material.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_header_gallery.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../domain/entities/matchmaker_user_profile.dart';
import 'matchmaker_above_image_section.dart';
import 'matchmaker_profile_header.dart';
import 'matchmaker_profile_status_banner.dart';

/// Read surface for the matchmaker profile detail: gallery hero → identity
/// title card (overlapping the gallery) → status banner → the matchmaker-only
/// basic-info card → the profile sections. The gallery and `PlacementRenderer`
/// are reused from the profile feature in its CARD layout
/// (`asCards: true, includeNarrative: true`), so the نبذة + every section read
/// exactly like the user-side full profile — only the hero differs (gallery,
/// no match-score overlay).
///
/// `PlacementRenderer` skips the `aboveImage` placement (it's drawn over the
/// photo on the user-side card), so it's surfaced here as its own card via
/// [MatchmakerAboveImageSection] — the matchmaker never sees that card and
/// needs residence / job / nationality to review the profile.
class MatchmakerProfileBody extends StatelessWidget {
  const MatchmakerProfileBody({super.key, required this.profile});

  final MatchmakerUserProfile profile;

  /// Magnitude by which the hero card overlaps the gallery's bottom edge —
  /// the identity's photo-into-content layered look.
  static const double _heroOverlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final aboveImage = _aboveImageOf(profile.placements);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileHeaderGallery(images: profile.images),
        SoftScaleIn(
          duration: QeranMotion.gentle,
          beginScale: 0.97,
          child: Transform.translate(
            offset: const Offset(0, -_heroOverlap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                MatchmakerProfileHeader(
                  name: profile.name,
                  age: profile.age,
                  gender: profile.gender,
                  email: profile.email,
                ),
                MatchmakerProfileStatusBanner(status: profile.profileStatus),
                QeranSpacing.vs16,
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Matchmaker-only basic info (residence / job /
                      // nationality) as its own card — the reviewer never saw
                      // the discovery card that normally carries these fields.
                      if (aboveImage != null &&
                          aboveImage.items.isNotEmpty) ...[
                        QeranCard(
                          child: MatchmakerAboveImageSection(
                            placement: aboveImage,
                          ),
                        ),
                        QeranSpacing.vs16,
                      ],
                      // Same section-card composition as the user-side full
                      // profile: نبذة card + remaining sections, each in its
                      // own QeranCard.
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
        ),
      ],
    );
  }

  /// The `aboveImage` placement (residence / job / nationality), or `null`
  /// when the profile carries none.
  static Placement? _aboveImageOf(List<Placement> placements) {
    for (final p in placements) {
      if (p.code == PlacementCode.aboveImage) return p;
    }
    return null;
  }
}

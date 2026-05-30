import 'package:flutter/material.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_header_gallery.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../domain/entities/matchmaker_user_profile.dart';
import 'matchmaker_profile_header.dart';
import 'matchmaker_profile_status_banner.dart';

/// Read surface for the matchmaker profile detail: gallery hero → hero
/// title card (overlapping the gallery) → status banner → placements. The
/// gallery and `PlacementRenderer` are reused from the profile feature, so
/// the rendered sections match the user-side full profile exactly.
///
/// Note: `PlacementRenderer` intentionally skips the `aboveImage` placement
/// (it's drawn over the photo on the user-side card), so residence / job /
/// nationality are not surfaced here — same as the user-side full profile.
class MatchmakerProfileBody extends StatelessWidget {
  const MatchmakerProfileBody({super.key, required this.profile});

  final MatchmakerUserProfile profile;

  /// Magnitude by which the hero card overlaps the gallery's bottom edge —
  /// the identity's photo-into-content layered look.
  static const double _heroOverlap = 28.0;

  @override
  Widget build(BuildContext context) {
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
                QeranSpacing.vs24,
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
                  child: PlacementRenderer(placements: profile.placements),
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/other_profile.dart';
import '../../domain/entities/profile_entry_source.dart';
import 'placement/placement_renderer.dart';
import 'profile_header_gallery.dart';
import 'share_with_matchmaker_button.dart';

/// Composes the full profile read surface: gallery hero + overlapping
/// title card + placements + share-with-matchmaker action. The share
/// affordance is entry-source-gated.
class FullProfileBody extends StatelessWidget {
  final OtherProfile profile;
  final ProfileEntrySource entry;
  const FullProfileBody({
    super.key,
    required this.profile,
    required this.entry,
  });

  /// Magnitude by which the hero card overlaps the gallery's bottom
  /// edge — creates the identity's photo-into-content layered look.
  static const double _heroOverlap = 28.0;

  bool get _showShare {
    switch (entry) {
      case ProfileEntrySource.discovery:
      case ProfileEntrySource.likes:
      case ProfileEntrySource.matches:
      case ProfileEntrySource.matchmaker:
        return true;
      case ProfileEntrySource.chat:
      case ProfileEntrySource.settings:
      case ProfileEntrySource.mine:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileHeaderGallery(images: profile.images),
        // Gentle scale-in + fade for the entire reading surface. The
        // gallery above is stable; only the content sheet "settles in"
        // — calmer than scaling the photo itself.
        SoftScaleIn(
          duration: QeranMotion.gentle,
          beginScale: 0.97,
          child: Transform.translate(
            offset: const Offset(0, -_heroOverlap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroTitleCard(
                  name: profile.name,
                  age: profile.age,
                  matchPercent: profile.matchingScore,
                ),
                QeranSpacing.vs32,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: QeranSpacing.s20,
                  ),
                  child: PlacementRenderer(placements: profile.placements),
                ),
                if (_showShare) ...[
                  QeranSpacing.vs24,
                  ShareWithMatchmakerButton(userId: profile.id),
                ],
                QeranSpacing.vs32,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Lifted hero card that overlaps the gallery's bottom edge. Holds the
/// name/age headline, the verified mark, and (when scored) the
/// compatibility chip. A faint gold ring motif sits behind the card's
/// top-end corner.
class _HeroTitleCard extends StatelessWidget {
  final String name;
  final int? age;
  final double matchPercent;

  const _HeroTitleCard({
    required this.name,
    required this.age,
    required this.matchPercent,
  });

  @override
  Widget build(BuildContext context) {
    final title = age == null
        ? name
        : context.tr(
            LocaleKeys.profile_name_age_format,
            namedArgs: {'name': name, 'age': '$age'},
          );
    final scored = matchPercent > 0;
    final scoreLabel = scored
        ? context.tr(
            LocaleKeys.profile_compatibility_label,
            namedArgs: {'percent': '${matchPercent.round()}'},
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Quiet gold ring flourish behind the top-end corner. 6% alpha
          // — present but never competing with the photo above.
          Positioned(
            top: -18,
            right: -18,
            child: IgnorePointer(
              child: const RingMotif(
                color: QeranColors.gold,
                opacity: 0.08,
                size: 120,
                ringCount: 2,
                spacing: 12,
              ),
            ),
          ),
          QeranCard.hero(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: QeranTypography.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    QeranSpacing.hs8,
                    const Icon(
                      Icons.verified_rounded,
                      color: QeranColors.gold,
                      size: 22,
                    ),
                  ],
                ),
                if (scored) ...[
                  QeranSpacing.vs12,
                  QeranChip(
                    label: scoreLabel!,
                    variant: QeranChipVariant.score,
                    icon: Icons.favorite_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

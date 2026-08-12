import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/other_profile.dart';
import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import '../../domain/entities/profile_entry_source.dart';
import 'full_profile_content_skeleton.dart';
import 'full_profile_image_hero.dart';
import 'placement/about_me_section.dart';
import 'placement/inside_chips_section.dart';
import 'placement/placement_renderer.dart';

/// Whether the pinned share-with-matchmaker CTA applies for this entry source
/// (sharing another user with your matchmaker only makes sense from the
/// browsing surfaces). Shared with the screen that pins the CTA.
bool showShareForEntry(ProfileEntrySource entry) {
  switch (entry) {
    case ProfileEntrySource.discovery:
    case ProfileEntrySource.likes:
    case ProfileEntrySource.matches:
      return true;
    case ProfileEntrySource.chat:
    case ProfileEntrySource.settings:
    case ProfileEntrySource.mine:
      return false;
  }
}

/// Bottom clearance the scroll reserves (on top of the bottom safe-area inset)
/// so its last section can scroll clear of the pinned share CTA.
const double _kShareCtaClearance = 80.0;

/// Composes the full profile read surface: image hero + the نبذة عني main
/// card (attached to the image) + the remaining sections as separate
/// cards + the entry-gated share-with-matchmaker action. While the full
/// profile loads, a shimmer placeholder fills the content area.
class FullProfileBody extends StatelessWidget {
  final OtherProfile profile;
  final ProfileEntrySource entry;
  final bool isLoading;

  const FullProfileBody({
    super.key,
    required this.profile,
    required this.entry,
    this.isLoading = false,
  });

  /// How far the content sheet slides up under the image's bottom edge —
  /// the identity's photo-into-content layered look.
  static const double _sheetOverlap = QeranSpacing.s24;

  bool get _showShare => showShareForEntry(entry);
  bool get _showPinnedCta => _showShare || entry == ProfileEntrySource.chat;

  Placement? _find(PlacementCode code) {
    for (final p in profile.placements) {
      if (p.code == code) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FullProfileImageHero(profile: profile),
        Transform.translate(
          offset: const Offset(0, -_sheetOverlap),
          child: isLoading
              ? const FullProfileContentSkeleton()
              : _loadedContent(context),
        ),
      ],
    );
  }

  Widget _loadedContent(BuildContext context) {
    final aboutMe = _find(PlacementCode.aboutMe);
    final inside = _find(PlacementCode.insideCard);
    final hasInside = inside != null && inside.items.isNotEmpty;
    final hasMain = aboutMe != null || hasInside;

    return SoftScaleIn(
      duration: QeranMotion.gentle,
      beginScale: 0.97,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMain) _mainCard(aboutMe, inside, hasInside),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              QeranSpacing.s20,
              hasMain ? QeranSpacing.s16 : QeranSpacing.s24,
              QeranSpacing.s20,
              0,
            ),
            child: PlacementRenderer(
              placements: profile.placements,
              asCards: true,
              includeNarrative: false,
            ),
          ),
          // Trailing clearance so the last section scrolls clear of the
          // pinned share CTA (pinned by the screen, not part of this scroll).
          SizedBox(
            height: _showPinnedCta
                ? MediaQuery.of(context).padding.bottom + _kShareCtaClearance
                : QeranSpacing.s32,
          ),
        ],
      ),
    );
  }

  /// Main card — the نبذة عني narrative + inside-card chips, flush under
  /// the image with a rounded top (the photo-into-content "sheet").
  Widget _mainCard(Placement? aboutMe, Placement? inside, bool hasInside) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QeranRadii.panel),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s20,
        QeranSpacing.s24,
        QeranSpacing.s20,
        QeranSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (aboutMe != null) AboutMeSection(placement: aboutMe),
          if (hasInside) ...[
            if (aboutMe != null) QeranSpacing.vs16,
            InsideChipsSection(placement: inside!),
          ],
        ],
      ),
    );
  }
}

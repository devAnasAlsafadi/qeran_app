import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_photo_hero_motion.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/placement_code.dart';
import '../../domain/entities/placement_item.dart';
import 'discovery_blurred_image.dart';
import 'discovery_image_overlay.dart';
import 'discovery_title_row.dart';

/// Full-bleed image panel for a single Discovery profile. Renders the blurred
/// image with the Suggestions title row across its top (the title at the
/// start, «تعديل الفلترة» at the end, over a wine scrim), the centered privacy
/// lock + message, and at the bottom: name + age, the compatibility pill, and
/// the above-image chips. The row scrolls away with the photo.
class DiscoveryImagePanel extends StatelessWidget {
  final DiscoveryProfile profile;
  final VoidCallback? onTap;

  /// When `false`, the title row and its scrim are omitted.
  final bool showTitleRow;

  /// Opens the discovery filter sheet. Null renders the pill inert.
  final VoidCallback? onFilterTap;

  /// Fixed panel height. Null lets the panel fill its parent (the legacy
  /// flex-slot layout); the merged screen passes an explicit height because
  /// it lives inside a scroll, which has no bounded height to expand into.
  final double? height;

  /// Reveal factor for the compatibility pill: 0 hides it, 1 shows it in full.
  ///
  /// Null keeps the pill permanently visible. The merged screen drives it from
  /// the scroll so the score is absent on first open — the first impression is
  /// the person, not a percentage — and fades onto the photo as the user
  /// scrolls into the profile. The pill keeps its space either way, so the
  /// chips never jump when it arrives.
  final ValueListenable<double>? matchPillReveal;

  /// Minimum gap the identity block (name, pill, chips) keeps from the panel's
  /// bottom edge.
  ///
  /// The merged screen slides the نبذة عني sheet UP over that edge, so the
  /// last few dp of the panel are covered; the caller passes how much is
  /// covered plus the breathing room it wants, and the chips clear the sheet
  /// instead of being sliced by it.
  final double bottomContentInset;

  const DiscoveryImagePanel({
    super.key,
    required this.profile,
    this.onTap,
    this.showTitleRow = true,
    this.onFilterTap,
    this.height,
    this.bottomContentInset = 0,
    this.matchPillReveal,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _primaryImageUrl();
    final aboveItems = _aboveItems();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Hero(
              tag: profilePhotoHeroTag(profile.id),
              createRectTween: profilePhotoHeroRectTween,
              flightShuttleBuilder: profilePhotoFlightShuttle,
              child: DiscoveryBlurredImage(
                url: imageUrl,
                alignment: profilePhotoAlignment,
              ),
            )
          else
            Container(color: QeranColors.creamSurface),
          if (showTitleRow)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _TitleScrim.height,
              child: _TitleScrim(),
            ),
          // Identity + privacy overlays adapt independently when the available
          // height is reduced (small device, split screen, or a transient IME).
          // Each region scales down inside its own bounded flex slot, so neither
          // can collide with the other or produce a RenderFlex overflow.
          Positioned.fill(
            child: DiscoveryImageOverlay(
              name: profile.name,
              age: profile.age,
              matchPercent: profile.matchingScore,
              matchPillReveal: matchPillReveal,
              aboveItems: aboveItems,
              bottomContentInset: bottomContentInset,
              topClearance: showTitleRow ? DiscoveryTitleRow.extent : 0,
            ),
          ),
          if (showTitleRow)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // SafeArea keeps the row clear of a landscape notch; the shell's
              // top bar above already owns the status-bar inset.
              child: SafeArea(
                bottom: false,
                child: DiscoveryTitleRow(
                  onPhoto: true,
                  onEditFilters: onFilterTap,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _primaryImageUrl() {
    if (profile.images.isEmpty) return '';
    final primary = profile.images.firstWhere(
      (i) => i.isProfile,
      orElse: () => profile.images.first,
    );
    return primary.url;
  }

  List<PlacementItem> _aboveItems() {
    for (final p in profile.placements) {
      if (p.code == PlacementCode.aboveImage) return p.items;
    }
    return const <PlacementItem>[];
  }
}

/// Wine fading to clear down the photo's top, so the title row's paper type
/// reads on any photo.
class _TitleScrim extends StatelessWidget {
  const _TitleScrim();

  static const double height = 150;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              QeranColors.overlayTintDark,
              QeranColors.wine.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

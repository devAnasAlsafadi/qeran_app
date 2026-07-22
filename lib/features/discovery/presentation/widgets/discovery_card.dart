import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/features/notifications/presentation/routing/open_notifications.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_value.dart';
import '_image_overlay_button.dart';
import 'discovery_about_me.dart';
import 'discovery_blurred_image.dart';
import 'discovery_chips_above_image.dart';
import 'discovery_inside_chips.dart';
import 'discovery_privacy_message.dart';

/// Full-bleed image panel for a single Discovery profile (per Figma
/// `home.png`). Renders the blurred image with overlays for the filter
/// button (top-leading), notifications bell (top-trailing) with an
/// unread marker, the centered privacy lock + message, and at the
/// bottom: name + age plus the above-image chips. The top button row is
/// direction-locked to LTR so the filter stays on the left even in Arabic.
class DiscoveryImagePanel extends StatelessWidget {
  final DiscoveryProfile profile;
  final VoidCallback? onTap;

  /// When `false`, the top filter/notifications overlay row is omitted.
  /// Used by the next-card peek layer so the rear card stays purely
  /// decorative (no duplicate action icons).
  final bool showOverlayActions;

  const DiscoveryImagePanel({
    super.key,
    required this.profile,
    this.onTap,
    this.showOverlayActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _primaryImageUrl();
    final aboveItems = _aboveItems();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            DiscoveryBlurredImage(url: imageUrl)
          else
            Container(color: QeranColors.creamSurface),
          // Identity + privacy overlays. A single full-bleed Column reserves
          // space so the centered privacy group (gold lock + caption) and the
          // bottom identity group (name/age, then chips) can NEVER overlap,
          // whatever the photo height: the privacy group centers in the
          // flexible top region, the identity group pins to the photo's bottom.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: QeranSpacing.s16,
                end: QeranSpacing.s16,
                top: QeranSpacing.s16,
                bottom: QeranSpacing.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: Center(child: DiscoveryPrivacyMessage()),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NameAgeRow(name: profile.name, age: profile.age),
                      const SizedBox(height: QeranSpacing.s8),
                      DiscoveryChipsAboveImage(items: aboveItems),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showOverlayActions)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QeranSpacing.s16,
                    QeranSpacing.s8,
                    QeranSpacing.s16,
                    0,
                  ),
                  child: Row(
                    children: [
                      const ImageOverlayButton(
                        icon: Icons.tune_rounded,
                        onPressed: null,
                      ),
                      const Spacer(),
                      ImageOverlayButton(
                        icon: Icons.notifications_outlined,
                        onPressed: () => openNotifications(context),
                        badge: const OverlayUnreadDot(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

class _NameAgeRow extends StatelessWidget {
  final String name;
  final int age;

  const _NameAgeRow({required this.name, required this.age});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$name $age',
      style: QeranTypography.headline.copyWith(
        color: QeranColors.paper,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Content panel for the lower white sheet: the about-me header + body,
/// followed by the inside-card chips. Does NOT include its own white
/// background — the caller wraps it in the sheet container.
class DiscoveryInfoPanel extends StatelessWidget {
  final DiscoveryProfile profile;

  /// Body maxLines forwarded to [DiscoveryAboutMe]. `null` (default) shows
  /// the full about-me text (main card); the peek preview passes a small
  /// value to truncate.
  final int? maxLines;

  const DiscoveryInfoPanel({super.key, required this.profile, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final aboutMe = _aboutMe();
    final insideItems = _insideItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aboutMe != null) ...[
          DiscoveryAboutMe(
            header: aboutMe.name,
            text: _aboutMeText(aboutMe),
            maxLines: maxLines,
          ),
          // Increased breathing room between About Me text and the inside chips
          const SizedBox(height: QeranSpacing.s20),
        ],
        DiscoveryInsideChips(items: insideItems),
      ],
    );
  }

  Placement? _aboutMe() {
    for (final p in profile.placements) {
      if (p.code == PlacementCode.aboutMe) return p;
    }
    return null;
  }

  List<PlacementItem> _insideItems() {
    for (final p in profile.placements) {
      if (p.code == PlacementCode.insideCard) return p.items;
    }
    return const <PlacementItem>[];
  }

  String _aboutMeText(Placement section) {
    if (section.items.isEmpty) return '';
    final v = section.items.first.display;
    return switch (v) {
      PlacementSingle(value: final s) => s,
      PlacementMulti(values: final vs) => vs.join('\n'),
    };
  }
}

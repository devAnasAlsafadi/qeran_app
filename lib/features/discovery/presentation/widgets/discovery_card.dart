import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/features/notifications/presentation/routing/open_notifications.dart';
import 'package:qeran/features/profile/presentation/widgets/full_profile_image_overlays.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_photo_hero_motion.dart';
import 'package:qeran/generated/locale_keys.g.dart';

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

/// Full-bleed image panel for a single Discovery profile. Renders the blurred
/// image with the notifications bell (top-start) and filter button (top-end)
/// overlaid, the centered privacy lock + message, and at the bottom: name +
/// age, the compatibility pill, and the above-image chips.
///
/// The overlay row is fully directional: in Arabic (RTL) the bell sits on the
/// RIGHT and the filter on the LEFT, and it mirrors in English.
class DiscoveryImagePanel extends StatelessWidget {
  final DiscoveryProfile profile;
  final VoidCallback? onTap;

  /// When `false`, the top notifications/filter overlay row is omitted.
  final bool showOverlayActions;

  /// Opens the discovery filter sheet. Null renders the button inert.
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
    this.showOverlayActions = true,
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
          // Identity + privacy overlays adapt independently when the available
          // height is reduced (small device, split screen, or a transient IME).
          // Each region scales down inside its own bounded flex slot, so neither
          // can collide with the other or produce a RenderFlex overflow.
          Positioned.fill(
            child: _AdaptiveImageOverlay(
              name: profile.name,
              age: profile.age,
              matchPercent: profile.matchingScore,
              matchPillReveal: matchPillReveal,
              aboveItems: aboveItems,
              bottomContentInset: bottomContentInset,
            ),
          ),
          if (showOverlayActions)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // SafeArea keeps both buttons below the clock / notch now that
              // the photo runs edge-to-edge under a transparent status bar.
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QeranSpacing.s16,
                    QeranSpacing.s8,
                    QeranSpacing.s16,
                    0,
                  ),
                  // Bell at the START, filter at the END — in Arabic that puts
                  // the bell on the right and the filter on the left, and the
                  // Row mirrors itself for English.
                  child: Row(
                    children: [
                      ImageOverlayButton(
                        icon: Icons.notifications_outlined,
                        onPressed: () => openNotifications(context),
                        badge: const OverlayUnreadDot(),
                      ),
                      const Spacer(),
                      ImageOverlayButton(
                        icon: Icons.tune_rounded,
                        onPressed: onFilterTap,
                      ),
                    ],
                  ),
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

class _AdaptiveImageOverlay extends StatelessWidget {
  const _AdaptiveImageOverlay({
    required this.name,
    required this.age,
    required this.matchPercent,
    required this.matchPillReveal,
    required this.aboveItems,
    required this.bottomContentInset,
  });

  final String name;
  final int age;
  final double matchPercent;
  final ValueListenable<double>? matchPillReveal;
  final List<PlacementItem> aboveItems;
  final double bottomContentInset;

  static const double _compactHeight = 220;
  static const double _veryCompactHeight = 150;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < _compactHeight;
        final isVeryCompact = constraints.maxHeight < _veryCompactHeight;
        final horizontalPadding = isCompact
            ? QeranSpacing.s12
            : QeranSpacing.s16;
        final topPadding = isCompact ? QeranSpacing.s8 : QeranSpacing.s16;
        // Whichever is larger: the panel's own breathing room, or the space
        // the caller reserved for whatever overlaps the bottom edge.
        final bottomPadding = math.max(
          isCompact ? QeranSpacing.s8 : QeranSpacing.s20,
          bottomContentInset,
        );
        final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
            .clamp(0.0, double.infinity)
            .toDouble();

        final identity = SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _NameAgeRow(name: name, age: age),
              // Compatibility pill — directly under name+age, exactly where
              // the standalone full profile puts it. On the merged screen it
              // is a scroll reveal (see [matchPillReveal]).
              if (matchPercent > 0) ...[
                SizedBox(height: isCompact ? QeranSpacing.s4 : QeranSpacing.s8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _RevealingMatchPill(
                    percent: matchPercent,
                    reveal: matchPillReveal,
                  ),
                ),
              ],
              SizedBox(height: isCompact ? QeranSpacing.s4 : QeranSpacing.s8),
              DiscoveryChipsAboveImage(items: aboveItems),
            ],
          ),
        );

        // On regular portrait cards the privacy group belongs to the visual
        // center of the whole photo. Previously it occupied the first half of
        // a Column, which made the lock and caption look noticeably too high.
        // Compact landscape/split-screen layouts keep the collision-safe flex
        // arrangement below because the identity block shares very little
        // vertical space with the privacy message there.
        if (!isCompact) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SizedBox(
                    width: contentWidth,
                    child: const DiscoveryPrivacyMessage(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: horizontalPadding,
                  end: horizontalPadding,
                  top: topPadding,
                  bottom: bottomPadding,
                ),
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: identity,
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: horizontalPadding,
            end: horizontalPadding,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isVeryCompact)
                Expanded(
                  flex: isCompact ? 4 : 5,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: contentWidth,
                      child: const DiscoveryPrivacyMessage(),
                    ),
                  ),
                ),
              Expanded(
                flex: isVeryCompact ? 1 : (isCompact ? 6 : 5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.bottomStart,
                  child: identity,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The compatibility pill, faded in by [reveal].
///
/// Opacity only — the pill holds its space at every value, so the name and the
/// chips never shift while it appears. A null [reveal] renders it outright.
class _RevealingMatchPill extends StatelessWidget {
  const _RevealingMatchPill({required this.percent, required this.reveal});

  final double percent;
  final ValueListenable<double>? reveal;

  @override
  Widget build(BuildContext context) {
    final pill = ProfileMatchPill(
      label: context.tr(
        LocaleKeys.profile_compatibility_label,
        namedArgs: {'percent': '${percent.round()}'},
      ),
    );
    final source = reveal;
    if (source == null) return pill;
    return ValueListenableBuilder<double>(
      valueListenable: source,
      builder: (context, t, child) =>
          Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      child: pill,
    );
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

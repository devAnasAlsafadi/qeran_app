import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/notifications/presentation/routing/open_notifications.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_photo_hero_motion.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/placement_code.dart';
import '../../domain/entities/placement_item.dart';
import '_image_overlay_button.dart';
import 'discovery_blurred_image.dart';
import 'discovery_image_overlay.dart';

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
            child: DiscoveryImageOverlay(
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
              // SafeArea keeps both buttons clear of a landscape notch; the
              // shell's top bar above already owns the status-bar inset.
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
                      // The badge is a STATE, not decoration: it appears only
                      // while the server reports unread. It was pinned on
                      // unconditionally when the bell moved onto the photo,
                      // so it read as "you have mail" forever.
                      //
                      // A count, not a dot: the bell is the one surface where
                      // the number is worth reading — the tabs each stand for
                      // one thing, but the inbox pools everything.
                      BlocBuilder<BadgesCubit, BadgeCounts>(
                        bloc: sl<BadgesCubit>(),
                        builder: (context, counts) => Semantics(
                          label: LocaleKeys.notifications_bell_unread_a11y.t(
                            context,
                            namedArgs: {'count': '${counts.notifications}'},
                          ),
                          child: ImageOverlayButton(
                            icon: Icons.notifications_outlined,
                            onPressed: () => openNotifications(context),
                            badge: counts.notifications > 0
                                ? QeranCountBadge(count: counts.notifications)
                                : null,
                          ),
                        ),
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

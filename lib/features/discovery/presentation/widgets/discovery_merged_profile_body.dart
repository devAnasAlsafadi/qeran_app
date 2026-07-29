import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/features/profile/domain/entities/other_profile.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart'
    as profile_code;
import 'package:qeran/features/profile/domain/entities/placement_value.dart'
    as profile_value;
import 'package:qeran/features/profile/presentation/widgets/full_profile_content_skeleton.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';
import 'package:qeran/features/profile/presentation/widgets/share_with_matchmaker_button.dart';

import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_hydration_cubit.dart';
import '../blocs/discovery_hydration_state.dart';
import 'discovery_card.dart';

/// نبذة عني + the chips under it — the ONLY profile content above the fold.
///
/// Lives in the card's first screenful rather than here so it can be measured
/// as part of it; the rest of the profile follows in
/// [DiscoveryMergedProfileBody], below the fold.
///
/// Paints instantly from the deck payload, then upgrades: the deck only sends
/// a short PREVIEW of نبذة عني, so when the by-id hydrate lands its full
/// paragraph replaces the preview in place. No network wait, no truncation
/// left standing once the real text is available.
class DiscoveryProfileIntroSheet extends StatelessWidget {
  const DiscoveryProfileIntroSheet({super.key, required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
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
      child: BlocBuilder<DiscoveryHydrationCubit, DiscoveryHydrationState>(
        buildWhen: (prev, curr) =>
            prev.profileFor(profile.id) != curr.profileFor(profile.id),
        builder: (context, hydration) => DiscoveryInfoPanel(
          profile: profile,
          aboutMeOverride: _fullAboutMe(hydration.profileFor(profile.id)),
        ),
      ),
    );
  }

  /// The whole نبذة عني from the by-id profile, or null while only the deck's
  /// preview is available.
  String? _fullAboutMe(OtherProfile? hydrated) {
    if (hydrated == null) return null;
    for (final placement in hydrated.placements) {
      if (placement.code != profile_code.PlacementCode.aboutMe) continue;
      if (placement.items.isEmpty) return null;
      final value = placement.items.first.display;
      final text = switch (value) {
        profile_value.PlacementSingle(value: final s) => s,
        profile_value.PlacementMulti(values: final vs) => vs.join('\n'),
      };
      return text.trim().isEmpty ? null : text.trim();
    }
    return null;
  }
}

/// Everything BELOW the fold on the merged discovery screen — the content the
/// user used to have to tap through to a separate Full Profile screen for:
/// نبذة عن شريك الحياة, الدين ونمط الحياة, الحياة الزوجية, الاهتمامات, and the
/// "اسأل خطّابتي" CTA.
///
/// Comes from the by-id hydrate, which lands a moment after the card appears.
/// Until then this shows the same shimmer the standalone full profile uses. A
/// failed hydrate degrades silently — the user keeps the نبذة and the chips
/// above the fold, and like / skip / undo are unaffected.
class DiscoveryMergedProfileBody extends StatelessWidget {
  const DiscoveryMergedProfileBody({
    super.key,
    required this.profile,
    required this.bottomInset,
  });

  final DiscoveryProfile profile;

  /// Cleared at the end of the scroll so the last section (and the share CTA)
  /// can travel above the floating action cluster and the bottom nav.
  final double bottomInset;

  /// How far the intro sheet slides up under the photo's bottom edge — the
  /// identity's photo-into-content layered look, same value as the standalone
  /// full profile.
  static const double sheetOverlap = QeranSpacing.s24;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryHydrationCubit, DiscoveryHydrationState>(
      buildWhen: (prev, curr) =>
          prev.profileFor(profile.id) != curr.profileFor(profile.id) ||
          prev.isLoading(profile.id) != curr.isLoading(profile.id),
      builder: (context, hydration) {
        final hydrated = hydration.profileFor(profile.id);
        return ColoredBox(
          color: QeranColors.paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hydrated != null)
                _Sections(profile: hydrated)
              else if (hydration.isLoading(profile.id))
                const FullProfileContentSkeleton(),
              SizedBox(height: bottomInset),
            ],
          ),
        );
      },
    );
  }
}

/// The hydrated remainder, as cards, then the share CTA.
///
/// The CTA is INLINE at the end rather than pinned: the merged screen already
/// pins the like / skip / undo cluster above the bottom nav, so a second
/// pinned bar would collide with it. Reaching this by scrolling to the bottom
/// is also the right moment to offer it — the profile has just been read.
class _Sections extends StatelessWidget {
  const _Sections({required this.profile});

  final OtherProfile profile;

  @override
  Widget build(BuildContext context) {
    return SoftScaleIn(
      duration: QeranMotion.gentle,
      beginScale: 0.97,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              QeranSpacing.s20,
              0,
              QeranSpacing.s20,
              0,
            ),
            // Renders ONLY what the backend sent — an absent group emits
            // nothing, so no empty headers appear.
            child: PlacementRenderer(
              placements: profile.placements,
              asCards: true,
              includeNarrative: false,
            ),
          ),
          QeranSpacing.vs16,
          ShareWithMatchmakerButton(userId: profile.id),
        ],
      ),
    );
  }
}

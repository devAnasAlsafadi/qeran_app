import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_access_host.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_overlay.dart';

import '../../domain/entities/other_profile.dart';
import '../../domain/entities/placement_code.dart';
import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_value.dart';
import 'full_profile_image_overlays.dart';
import 'profile_header_gallery.dart';
import 'profile_photo_hero_motion.dart';

/// Full-profile image hero: the shared [ProfileHeaderGallery] with a
/// dark-wine scrim and the identity overlays (name + age, match-percentage
/// pill, aboveImage chips, and the gold privacy lock while the photo is
/// blurred). Mirrors the Discovery card's image panel and is fully
/// direction-aware.
class FullProfileImageHero extends StatelessWidget {
  final OtherProfile profile;

  const FullProfileImageHero({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final access = PhotoViewScope.maybeOf(context);
    final serverBlurred = profile.primaryImage?.isBlurred ?? false;
    final blurred = access?.effectiveBlur(serverBlurred) ?? serverBlurred;
    return Stack(
      children: [
        Hero(
          tag: profilePhotoHeroTag(profile.id),
          createRectTween: profilePhotoHeroRectTween,
          flightShuttleBuilder: profilePhotoFlightShuttle,
          child: Stack(
            children: [
              ProfileHeaderGallery(images: profile.images),
              const Positioned.fill(
                child: IgnorePointer(child: ProfileImageScrim()),
              ),
            ],
          ),
        ),
        if (blurred && !(access?.controlsAccess ?? false))
          const Positioned.fill(
            child: _ProfileHeroDetailsEntrance(
              child: IgnorePointer(child: Center(child: ProfilePrivacyLock())),
            ),
          ),
        PositionedDirectional(
          start: QeranSpacing.s16,
          end: QeranSpacing.s16,
          // Sits clear of the content sheet, which overlaps the image's
          // bottom edge by s24 — this leaves a comfortable gap above it.
          bottom: QeranSpacing.s48,
          child: _ProfileHeroDetailsEntrance(
            child: IgnorePointer(
              child: _HeroInfo(
                name: profile.name,
                age: profile.age,
                matchPercent: profile.matchingScore,
                chips: _aboveItems(),
              ),
            ),
          ),
        ),
        const PhotoViewOverlay(),
      ],
    );
  }

  List<PlacementItem> _aboveItems() {
    for (final p in profile.placements) {
      if (p.code == PlacementCode.aboveImage) return p.items;
    }
    return const <PlacementItem>[];
  }
}

class _ProfileHeroDetailsEntrance extends StatelessWidget {
  const _ProfileHeroDetailsEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation == null) return child;

    final reveal = CurvedAnimation(
      parent: routeAnimation,
      curve: const Interval(0.58, 1, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: reveal,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.045),
          end: Offset.zero,
        ).animate(reveal),
        child: child,
      ),
    );
  }
}

class _HeroInfo extends StatelessWidget {
  final String name;
  final int? age;
  final double matchPercent;
  final List<PlacementItem> chips;

  const _HeroInfo({
    required this.name,
    required this.age,
    required this.matchPercent,
    required this.chips,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: QeranTypography.headline.copyWith(
            color: QeranColors.paper,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (scored) ...[
          const SizedBox(height: QeranSpacing.s8),
          ProfileMatchPill(
            label: context.tr(
              LocaleKeys.profile_compatibility_label,
              namedArgs: {'percent': '${matchPercent.round()}'},
            ),
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: QeranSpacing.s12),
          Wrap(
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s8,
            children: chips
                .map(
                  (i) => ProfileOverlayChip(
                    label: _displayText(i.display),
                    icon: _iconFor(i.question),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  String _displayText(PlacementValue value) {
    return switch (value) {
      PlacementSingle(value: final v) => v,
      PlacementMulti(values: final vs) => vs.join('، '),
    };
  }

  /// Heuristic icon for the overlay chips — matches on the Arabic
  /// question text (the only stable locale-aware signal available).
  IconData? _iconFor(String question) {
    if (question.contains('الجنسية') || question.contains('جنسية')) {
      return Icons.public;
    }
    if (question.contains('المهنة') ||
        question.contains('الوظيف') ||
        question.contains('العمل')) {
      return Icons.work_outline_rounded;
    }
    if (question.contains('الإقامة') ||
        question.contains('السكن') ||
        question.contains('المدينة') ||
        question.contains('الدولة') ||
        question.contains('مكان')) {
      return Icons.location_on_outlined;
    }
    return null;
  }
}

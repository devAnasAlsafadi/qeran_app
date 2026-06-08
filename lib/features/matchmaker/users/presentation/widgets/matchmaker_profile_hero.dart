import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';
import 'package:qeran/features/profile/presentation/widgets/full_profile_image_overlays.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_header_gallery.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_user_profile.dart';

/// Matchmaker profile hero — the SAME photo-overlay presentation as the
/// user-side `FullProfileImageHero`, recomposed from the shared LEAF widgets
/// ([ProfileHeaderGallery] + [ProfileImageScrim] + [ProfileOverlayChip]) so the
/// look is unified without touching any user-app file. Identity (name + age)
/// and the above-image fields (residence / job / nationality) overlay the
/// photo.
///
/// The verified badge and match pill are intentionally OMITTED — neither
/// applies to a profile the matchmaker is reviewing (no match score; the
/// reviewer isn't asserting verification). Matchmaker images are always
/// unblurred, so there is no scrim privacy-lock.
class MatchmakerProfileHero extends StatelessWidget {
  const MatchmakerProfileHero({super.key, required this.profile});

  final MatchmakerUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProfileHeaderGallery(images: profile.images),
        const Positioned.fill(
          child: IgnorePointer(child: ProfileImageScrim()),
        ),
        PositionedDirectional(
          start: QeranSpacing.s16,
          end: QeranSpacing.s16,
          // Sits clear of the content sheet, which overlaps the image's bottom
          // edge — leaves a comfortable gap above it (mirrors the user side).
          bottom: QeranSpacing.s48,
          child: IgnorePointer(
            child: _HeroInfo(
              name: profile.name,
              age: profile.age,
              chips: _aboveItems(),
            ),
          ),
        ),
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

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({required this.name, required this.age, required this.chips});

  final String name;
  final int? age;
  final List<PlacementItem> chips;

  @override
  Widget build(BuildContext context) {
    final title = age == null
        ? name
        : context.tr(
            LocaleKeys.profile_name_age_format,
            namedArgs: {'name': name, 'age': '$age'},
          );
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
        if (chips.isNotEmpty) ...[
          QeranSpacing.vs12,
          Wrap(
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s8,
            children: chips
                .map((i) => ProfileOverlayChip(
                      label: _displayText(i.display),
                      icon: _iconFor(i.question),
                    ))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  String _displayText(PlacementValue value) => switch (value) {
        PlacementSingle(value: final v) => v,
        PlacementMulti(values: final vs) => vs.join('، '),
      };

  /// Heuristic icon for the overlay chips — matches on the Arabic question
  /// text (the only stable locale-aware signal), mirroring the user side.
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

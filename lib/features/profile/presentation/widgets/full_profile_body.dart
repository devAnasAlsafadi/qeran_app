import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/other_profile.dart';
import '../../domain/entities/profile_entry_source.dart';
import 'matching_score_card.dart';
import 'placement/placement_renderer.dart';
import 'profile_header_gallery.dart';
import 'share_with_matchmaker_button.dart';

/// Composes the full profile read surface: gallery hero + name/age
/// title + matching score + placements + share-with-matchmaker action.
/// The share affordance is entry-source-gated — hidden in chat (the
/// matchmaker shared this with us already) and on My Profile.
class FullProfileBody extends StatelessWidget {
  final OtherProfile profile;
  final ProfileEntrySource entry;
  const FullProfileBody({
    super.key,
    required this.profile,
    required this.entry,
  });

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
        QeranSpacing.vs20,
        _TitleRow(name: profile.name, age: profile.age),
        QeranSpacing.vs8,
        MatchingScoreCard(percent: profile.matchingScore),
        QeranSpacing.vs8,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
          child: PlacementRenderer(placements: profile.placements),
        ),
        if (_showShare) ...[
          QeranSpacing.vs24,
          ShareWithMatchmakerButton(userId: profile.id),
        ],
        QeranSpacing.vs32,
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String name;
  final int? age;
  const _TitleRow({required this.name, required this.age});

  @override
  Widget build(BuildContext context) {
    final title = age == null
        ? name
        : context.tr(
            LocaleKeys.profile_name_age_format,
            namedArgs: {'name': name, 'age': '$age'},
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
      child: Row(
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
    );
  }
}

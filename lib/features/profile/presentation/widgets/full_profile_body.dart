import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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

  /// Share button only makes sense for peer profiles the user might
  /// want their matchmaker to weigh in on.
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
        const SizedBox(height: AppDimens.p16),
        _TitleRow(name: profile.name, age: profile.age),
        const SizedBox(height: AppDimens.p8),
        MatchingScoreCard(percent: profile.matchingScore),
        const SizedBox(height: AppDimens.p8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
          child: PlacementRenderer(placements: profile.placements),
        ),
        if (_showShare) ...[
          const SizedBox(height: AppDimens.p24),
          ShareWithMatchmakerButton(userId: profile.id),
        ],
        const SizedBox(height: AppDimens.p32),
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
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimens.p8),
          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 22,
          ),
        ],
      ),
    );
  }
}

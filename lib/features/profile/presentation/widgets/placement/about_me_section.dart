import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_value.dart';
import 'profile_section_header.dart';

/// Renders the `aboutMe` placement — server-supplied paragraph the
/// user wrote about themselves. Truncates to [maxLines] when set so
/// the same widget powers both the full screen and a card preview.
class AboutMeSection extends StatelessWidget {
  final Placement placement;
  final int? maxLines;
  const AboutMeSection({
    super.key,
    required this.placement,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final body = _bodyText();
    if (body.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileSectionHeader(
          title: placement.name,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: AppDimens.p8),
        Text(
          body,
          maxLines: maxLines,
          overflow:
              maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  String _bodyText() {
    if (placement.items.isEmpty) return '';
    final v = placement.items.first.display;
    return switch (v) {
      PlacementSingle(value: final s) => s.trim(),
      PlacementMulti(values: final vs) => vs.join('\n').trim(),
    };
  }
}

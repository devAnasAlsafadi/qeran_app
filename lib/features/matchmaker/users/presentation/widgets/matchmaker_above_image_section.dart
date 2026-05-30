import 'package:flutter/material.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/items/placement_item_renderer.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/profile_section_header.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Renders the `aboveImage` placement (residence / job title / nationality)
/// as a normal Q&A section. The shared `PlacementRenderer` deliberately
/// skips this placement — on the user side those fields are drawn over the
/// discovery card — but the matchmaker never sees that card, so for a
/// reviewer they'd otherwise be invisible.
///
/// Mirrors `QaDefaultSection`'s structure (header + one
/// `PlacementItemRenderer` per item) with a reviewer-facing title instead
/// of the layout-hint `placementName` ("فوق الصورة").
class MatchmakerAboveImageSection extends StatelessWidget {
  const MatchmakerAboveImageSection({super.key, required this.placement});

  final Placement placement;

  @override
  Widget build(BuildContext context) {
    if (placement.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileSectionHeader(
          title: LocaleKeys.matchmaker_profile_basic_info.t(context),
          icon: Icons.badge_outlined,
        ),
        QeranSpacing.vs8,
        for (final item in placement.items) PlacementItemRenderer(item: item),
      ],
    );
  }
}

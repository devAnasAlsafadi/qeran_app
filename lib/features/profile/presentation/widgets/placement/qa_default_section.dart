import 'package:flutter/material.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../../domain/entities/placement.dart';
import 'items/placement_item_renderer.dart';
import 'profile_section_header.dart';

/// Generic Q&A section — used for any `defaultGroup` placement and as
/// the graceful fallback for unrecognised codes. Renders the header
/// plus one row per item via [PlacementItemRenderer].
class QaDefaultSection extends StatelessWidget {
  final Placement placement;
  const QaDefaultSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    if (placement.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileSectionHeader(
          title: placement.name,
          icon: Icons.list_alt_rounded,
        ),
        const SizedBox(height: AppDimens.p8),
        for (final item in placement.items)
          PlacementItemRenderer(item: item),
      ],
    );
  }
}

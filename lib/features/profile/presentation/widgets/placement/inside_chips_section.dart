import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_item.dart';
import '../../../domain/entities/placement_value.dart';

/// Renders the `insideCard` placement (height, weight, marital status,
/// ethnicity, etc.) as outlined tag chips. Same widget feeds the
/// Discovery card preview AND the full details screen — no parallel
/// chip rendering.
class InsideChipsSection extends StatelessWidget {
  final Placement placement;
  const InsideChipsSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    if (placement.items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppDimens.p8,
      runSpacing: AppDimens.p8,
      children: placement.items
          .map((i) => _OutlinedTag(item: i))
          .toList(growable: false),
    );
  }
}

class _OutlinedTag extends StatelessWidget {
  final PlacementItem item;
  const _OutlinedTag({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p4 + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.r8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        _label(item.display),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _label(PlacementValue v) {
    return switch (v) {
      PlacementSingle(value: final s) => s,
      PlacementMulti(values: final vs) => vs.join(' · '),
    };
  }
}

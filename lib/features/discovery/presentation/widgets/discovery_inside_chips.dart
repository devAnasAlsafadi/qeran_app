import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../domain/entities/placement_item.dart';
import '_chip_display.dart';
import '_placement_icons.dart';

/// Outlined tag chips with a burgundy icon, used inside the card body.
/// Border-radius 8px per the design system.
class DiscoveryInsideChips extends StatelessWidget {
  final List<PlacementItem> items;

  const DiscoveryInsideChips({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppDimens.p8,
      runSpacing: AppDimens.p8,
      children: items.map((i) => _OutlinedTag(item: i)).toList(),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconForQuestionId(item.questionId),
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimens.p4 + 2),
          Text(
            chipDisplay(item, context),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

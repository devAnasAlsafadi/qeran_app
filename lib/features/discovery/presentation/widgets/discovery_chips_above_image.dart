import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_value.dart';
import '_placement_icons.dart';

/// White pill chips overlaid at the top of the blurred image. One per
/// `aboveImage` placement item.
class DiscoveryChipsAboveImage extends StatelessWidget {
  final List<PlacementItem> items;

  const DiscoveryChipsAboveImage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppDimens.p8,
      runSpacing: AppDimens.p8,
      children: items.map((i) => _PillChip(item: i)).toList(),
    );
  }
}

class _PillChip extends StatelessWidget {
  final PlacementItem item;
  const _PillChip({required this.item});

  @override
  Widget build(BuildContext context) {
    // Dark translucent pill, white icon + text. Reads as an image
    // overlay rather than a white form chip (per Figma `home.png`).
    // The 35% black backdrop matches the overlay buttons' style so the
    // top of the image area feels visually consistent.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p4 + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconForQuestionId(item.questionId),
            size: 14,
            color: AppColors.white,
          ),
          const SizedBox(width: AppDimens.p4 + 2),
          Text(
            _displayText(item.display),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _displayText(PlacementValue value) {
    return switch (value) {
      PlacementSingle(value: final v) => v,
      PlacementMulti(values: final vs) => vs.join('، '),
    };
  }
}

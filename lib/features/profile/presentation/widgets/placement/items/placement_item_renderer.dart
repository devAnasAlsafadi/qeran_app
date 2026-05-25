import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../../../domain/entities/placement_item.dart';
import '../../../../domain/entities/placement_value.dart';
import 'inline_chip.dart';

/// Item-level dispatcher. Picks a renderer based on the sealed
/// `PlacementValue` variant: text for single answers, wrapped chips
/// for multi answers. Knowing the `PlacementItemType` is optional —
/// this surface is purely value-shape driven so a new server type
/// never breaks rendering.
class PlacementItemRenderer extends StatelessWidget {
  final PlacementItem item;
  const PlacementItemRenderer({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.question,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          _AnswerView(value: item.display),
        ],
      ),
    );
  }
}

class _AnswerView extends StatelessWidget {
  final PlacementValue value;
  const _AnswerView({required this.value});

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      PlacementSingle(value: final s) => Text(
          s,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      PlacementMulti(values: final vs) => Wrap(
          spacing: AppDimens.p8,
          runSpacing: 6,
          children: vs
              .where((v) => v.trim().isNotEmpty)
              .map(InlineChip.new)
              .toList(growable: false),
        ),
    };
  }
}

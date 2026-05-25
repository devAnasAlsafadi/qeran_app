import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../../../domain/entities/placement_item.dart';
import '../../../../domain/entities/placement_value.dart';
import 'inline_chip.dart';

/// Item-level dispatcher. Picks a renderer based on the sealed
/// `PlacementValue` variant: text for single answers, wrapped chips
/// for multi answers.
class PlacementItemRenderer extends StatelessWidget {
  final PlacementItem item;
  const PlacementItemRenderer({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.question, style: QeranTypography.caption),
          const SizedBox(height: QeranSpacing.s6),
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
          style: QeranTypography.subtitle,
        ),
      PlacementMulti(values: final vs) => Wrap(
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s6,
          children: vs
              .where((v) => v.trim().isNotEmpty)
              .map(InlineChip.new)
              .toList(growable: false),
        ),
    };
  }
}

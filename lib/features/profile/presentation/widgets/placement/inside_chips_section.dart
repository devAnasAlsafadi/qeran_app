import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_item.dart';
import '../../../domain/entities/placement_value.dart';

/// Renders the `insideCard` placement (height, weight, marital status,
/// ethnicity, etc.) as gold-tinted chips with a small contextual icon
/// and, where applicable, a unit suffix (`كغ` / `سم`). Same widget
/// feeds both the profile-details and my-profile surfaces.
///
/// The icon mapping is heuristic on the Arabic question text — the
/// most stable signal we have without a categorical question-key from
/// the backend. Items that don't match a known category render as
/// label-only chips (no icon), so adding a new placement question on
/// the server never regresses an unknown row to a broken visual.
class InsideChipsSection extends StatelessWidget {
  final Placement placement;

  /// Chip fill variant. Defaults to [QeranChipVariant.interest] (the gold-tint
  /// used by the user-app + my-profile surfaces — UNCHANGED). The matchmaker
  /// profile passes [QeranChipVariant.inside] (clean white + hairline) so the
  /// chips don't read as a beige smudge against the wine identity.
  final QeranChipVariant variant;

  const InsideChipsSection({
    super.key,
    required this.placement,
    this.variant = QeranChipVariant.interest,
  });

  @override
  Widget build(BuildContext context) {
    if (placement.items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: QeranSpacing.s12,
      runSpacing: QeranSpacing.s12,
      children: placement.items.map(_buildChip).toList(growable: false),
    );
  }

  Widget _buildChip(PlacementItem item) {
    final meta = _resolveMeta(item.question);
    final raw = _displayString(item.display);
    final label = _withUnit(raw, meta.unit);
    return QeranChip(
      label: label,
      variant: variant,
      icon: meta.icon,
    );
  }

  String _displayString(PlacementValue value) {
    return switch (value) {
      PlacementSingle(value: final s) => s,
      PlacementMulti(values: final vs) => vs.join(' · '),
    };
  }

  String _withUnit(String value, String? unit) {
    if (unit == null) return value;
    // Skip the suffix if the backend already ships a unit so we don't
    // produce "70 كيلو كغ".
    const existing = ['كغ', 'كيلو', 'كيلوغرام', 'سم', 'سنتيمتر'];
    for (final tail in existing) {
      if (value.endsWith(tail)) return value;
    }
    return '$value$unit';
  }

  /// Heuristic icon + unit resolver. Match on the Arabic question
  /// text — the backend's `question` field is the only stable
  /// (locale-aware) signal we have for category. Substring matching
  /// covers minor wording variations like "الوزن (كغ)".
  _ChipMeta _resolveMeta(String question) {
    if (question.contains('الوزن')) {
      return const _ChipMeta(
        icon: Icons.monitor_weight_outlined,
        unit: ' كغ',
      );
    }
    if (question.contains('الطول')) {
      return const _ChipMeta(icon: Icons.height_rounded, unit: ' سم');
    }
    if (question.contains('لون البشرة')) {
      return const _ChipMeta(icon: Icons.palette_outlined);
    }
    if (question.contains('لون العيون')) {
      return const _ChipMeta(icon: Icons.remove_red_eye_outlined);
    }
    if (question.contains('لون الشعر')) {
      return const _ChipMeta(icon: Icons.brush_outlined);
    }
    if (question.contains('بنية الجسم') || question.contains('البنية')) {
      return const _ChipMeta(icon: Icons.accessibility_new_rounded);
    }
    if (question.contains('الحالة الاجتماعية')) {
      return const _ChipMeta(icon: Icons.favorite_border);
    }
    if (question.contains('التدخين')) {
      return const _ChipMeta(icon: Icons.smoking_rooms_outlined);
    }
    return const _ChipMeta();
  }
}

class _ChipMeta {
  final IconData? icon;
  final String? unit;
  const _ChipMeta({this.icon, this.unit});
}

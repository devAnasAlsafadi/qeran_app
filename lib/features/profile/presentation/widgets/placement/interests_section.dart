import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_value.dart';
import 'profile_section_header.dart';

/// Flat interests section — wine header + wrap of pill chips.
class InterestsSection extends StatelessWidget {
  final Placement placement;
  const InterestsSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    final chips = _collectChips();
    if (chips.isEmpty) return const SizedBox.shrink();
    final title = placement.name.trim().isNotEmpty
        ? placement.name
        : LocaleKeys.profile_details_interests_title.t(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileSectionHeader(
          title: title,
          icon: Icons.auto_awesome_outlined,
        ),
        QeranSpacing.vs12,
        Wrap(
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s8,
          children: chips
              .map(
                (label) => QeranChip(
                  label: label,
                  variant: QeranChipVariant.interest,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  List<String> _collectChips() {
    final out = <String>[];
    for (final item in placement.items) {
      switch (item.display) {
        case PlacementSingle(value: final v):
          final t = v.trim();
          if (t.isNotEmpty) out.add(t);
        case PlacementMulti(values: final vs):
          for (final v in vs) {
            final t = v.trim();
            if (t.isNotEmpty) out.add(t);
          }
      }
    }
    return out;
  }
}

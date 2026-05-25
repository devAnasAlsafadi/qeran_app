import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_value.dart';
import 'profile_section_header.dart';

class AboutPartnerSection extends StatelessWidget {
  final Placement placement;
  const AboutPartnerSection({super.key, required this.placement});

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
          icon: Icons.favorite_outline_rounded,
        ),
        QeranSpacing.vs8,
        Text(body, style: QeranTypography.body),
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

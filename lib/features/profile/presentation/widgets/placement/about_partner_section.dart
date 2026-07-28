import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_value.dart';
import 'items/editable_text_answer.dart';
import 'profile_section_header.dart';

/// Renders the `aboutPartner` placement — the paragraph the user wrote about
/// the spouse they're looking for.
///
/// Wrapped in [EditableTextAnswer] for the matchmaker's edit pencil, for the
/// same reason as [AboutMeSection]: this section paints its body directly and
/// so never reached `PlacementItemRenderer`, the only thing attaching the
/// pencil. A pass-through outside the matchmaker edit scope.
class AboutPartnerSection extends StatelessWidget {
  final Placement placement;
  const AboutPartnerSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    final body = _bodyText();
    // No body → nothing to render, and therefore nothing to edit either.
    if (body.isEmpty) return const SizedBox.shrink();
    return EditableTextAnswer(
      item: placement.items.isEmpty ? null : placement.items.first,
      // Level with the section header (see AboutMeSection).
      affordancePadding: EdgeInsets.zero,
      child: Column(
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
      ),
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

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_value.dart';
import 'items/editable_text_answer.dart';
import 'profile_section_header.dart';

/// Renders the `aboutMe` placement — server-supplied paragraph the
/// user wrote about themselves. Truncates to [maxLines] when set so
/// the same widget powers both the full screen and a card preview.
///
/// Wrapped in [EditableTextAnswer] so the matchmaker's edit pencil appears
/// here, exactly as it does on Q&A rows. It used to be missing because this
/// section paints its body directly instead of going through
/// `PlacementItemRenderer`, which was the only thing attaching the pencil.
/// Outside the matchmaker edit scope the wrapper is a pass-through, so the
/// user app and my-profile are byte-identical.
class AboutMeSection extends StatelessWidget {
  final Placement placement;
  final int? maxLines;
  const AboutMeSection({
    super.key,
    required this.placement,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final body = _bodyText();
    // No body → nothing to render, and therefore nothing to edit either: the
    // pencil is never drawn for a field the backend did not send.
    if (body.isEmpty) return const SizedBox.shrink();
    return EditableTextAnswer(
      item: placement.items.isEmpty ? null : placement.items.first,
      // Flush with the section header rather than the Q&A rows' inset, so the
      // pencil sits level with the header line.
      affordancePadding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileSectionHeader(
            title: placement.name,
            icon: Icons.person_outline_rounded,
          ),
          QeranSpacing.vs8,
          Text(
            body,
            maxLines: maxLines,
            overflow:
                maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
            style: QeranTypography.body,
          ),
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

import 'package:flutter/material.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_code.dart';
import 'about_me_section.dart';
import 'about_partner_section.dart';
import 'inside_chips_section.dart';
import 'interests_section.dart';
import 'profile_section_header.dart';
import 'qa_default_section.dart';

/// Top-level section dispatcher. Bucket-sorts placements by [PlacementCode]
/// once, then emits widgets in a deterministic order:
///   aboutMe → insideChips → aboutPartner → defaultGroup[*] → interests
/// `aboveImage` is intentionally NOT rendered here — it's already drawn
/// inside the image card and ignoring it here keeps the body clean.
///
/// New backend codes the client doesn't recognise are mapped to
/// [PlacementCode.defaultGroup] by the entity parser, so they show up
/// as a generic Q&A section instead of disappearing.
class PlacementRenderer extends StatelessWidget {
  final List<Placement> placements;

  /// When true (default), divider hairlines separate sections.
  /// Discovery preview turns this off because it only shows one slice.
  final bool withDividers;

  const PlacementRenderer({
    super.key,
    required this.placements,
    this.withDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (sections.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          sections[i],
          if (withDividers && i != sections.length - 1)
            const ProfileSectionDivider(),
        ],
      ],
    );
  }

  List<Widget> _buildSections() {
    Placement? aboutMe;
    Placement? insideCard;
    Placement? aboutPartner;
    Placement? interests;
    final defaults = <Placement>[];

    for (final p in placements) {
      switch (p.code) {
        case PlacementCode.aboutMe:
          aboutMe ??= p;
        case PlacementCode.insideCard:
          insideCard ??= p;
        case PlacementCode.aboutPartner:
          aboutPartner ??= p;
        case PlacementCode.interests:
          interests ??= p;
        case PlacementCode.defaultGroup:
          defaults.add(p);
        case PlacementCode.aboveImage:
          break;
      }
    }

    final out = <Widget>[];
    if (aboutMe != null) out.add(AboutMeSection(placement: aboutMe));
    if (insideCard != null && insideCard.items.isNotEmpty) {
      out.add(InsideChipsSection(placement: insideCard));
    }
    if (aboutPartner != null) {
      out.add(AboutPartnerSection(placement: aboutPartner));
    }
    for (final d in defaults) {
      out.add(QaDefaultSection(placement: d));
    }
    if (interests != null) out.add(InterestsSection(placement: interests));
    return out;
  }
}

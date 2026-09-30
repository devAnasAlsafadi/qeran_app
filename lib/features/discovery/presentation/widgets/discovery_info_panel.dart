import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/placement.dart';
import '../../domain/entities/placement_code.dart';
import '../../domain/entities/placement_item.dart';
import '../../domain/entities/placement_value.dart';
import 'discovery_about_me.dart';
import 'discovery_inside_chips.dart';

/// Content panel for the lower white sheet: the about-me header + body,
/// followed by the inside-card chips. Does NOT include its own white
/// background — the caller wraps it in the sheet container.
class DiscoveryInfoPanel extends StatelessWidget {
  final DiscoveryProfile profile;

  /// Body maxLines forwarded to [DiscoveryAboutMe]. `null` (default) shows
  /// the full about-me text (main card); the peek preview passes a small
  /// value to truncate.
  final int? maxLines;

  /// Replaces the deck payload's about-me body when set.
  ///
  /// The deck sends a SHORT preview of نبذة عني; the by-id profile carries the
  /// whole thing. The caller passes the fuller text through once it has landed
  /// so the user reads the paragraph, not its first line.
  final String? aboutMeOverride;

  const DiscoveryInfoPanel({
    super.key,
    required this.profile,
    this.maxLines,
    this.aboutMeOverride,
  });

  @override
  Widget build(BuildContext context) {
    final aboutMe = _aboutMe();
    final insideItems = _insideItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aboutMe != null) ...[
          DiscoveryAboutMe(
            header: aboutMe.name,
            text: aboutMeOverride?.trim().isNotEmpty ?? false
                ? aboutMeOverride!.trim()
                : _aboutMeText(aboutMe),
            maxLines: maxLines,
          ),
          // Increased breathing room between About Me text and the inside chips
          const SizedBox(height: QeranSpacing.s20),
        ],
        DiscoveryInsideChips(items: insideItems),
      ],
    );
  }

  Placement? _aboutMe() {
    for (final p in profile.placements) {
      if (p.code == PlacementCode.aboutMe) return p;
    }
    return null;
  }

  List<PlacementItem> _insideItems() {
    for (final p in profile.placements) {
      if (p.code == PlacementCode.insideCard) return p.items;
    }
    return const <PlacementItem>[];
  }

  String _aboutMeText(Placement section) {
    if (section.items.isEmpty) return '';
    final v = section.items.first.display;
    return switch (v) {
      PlacementSingle(value: final s) => s,
      PlacementMulti(values: final vs) => vs.join('\n'),
    };
  }
}

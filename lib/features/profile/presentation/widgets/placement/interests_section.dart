import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_item.dart';
import '../../../domain/entities/placement_value.dart';
import 'profile_section_header.dart';

/// The `interests` placement — one titled chip group PER ITEM.
///
/// The backend puts several distinct questions inside this ONE group: the
/// personal traits (questionId 22) and the hobbies (23) both arrive as items of
/// a single placement called "الاهتمامات". This used to flatten every item into
/// one wrap under the group's name, so the two answers merged into a single
/// nameless pile of chips and the traits question looked like it was missing —
/// it was on screen, unlabelled, mixed in with the hobbies.
///
/// Each item now keeps its own heading, taken from `item.question` (never a
/// hardcoded id: the backend owns both the wording and how many questions live
/// here). An item the user left blank contributes nothing.
class InterestsSection extends StatelessWidget {
  final Placement placement;
  const InterestsSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) QeranSpacing.vs20,
          _InterestGroup(
            title: _titleFor(context, groups[i].item),
            chips: groups[i].chips,
          ),
        ],
      ],
    );
  }

  /// One entry per answered item, in the order the backend sent them.
  List<({PlacementItem item, List<String> chips})> _groups() {
    final out = <({PlacementItem item, List<String> chips})>[];
    for (final item in placement.items) {
      final chips = _chipsOf(item);
      if (chips.isNotEmpty) out.add((item: item, chips: chips));
    }
    return out;
  }

  /// The item's own question wins — it is the specific label ("الصفات
  /// الشخصية"), where the placement name is the shared bucket ("الاهتمامات").
  String _titleFor(BuildContext context, PlacementItem item) {
    final question = item.question.trim();
    if (question.isNotEmpty) return question;
    final group = placement.name.trim();
    if (group.isNotEmpty) return group;
    return LocaleKeys.profile_details_interests_title.t(context);
  }

  /// Reads `display` (emoji + Arabic), never `value` — that one is the wire
  /// code, for logic only. Tolerates both shapes: a user who picked a single
  /// option gets a String back, several gets a List.
  List<String> _chipsOf(PlacementItem item) {
    final out = <String>[];
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
    return out;
  }
}

class _InterestGroup extends StatelessWidget {
  const _InterestGroup({required this.title, required this.chips});

  final String title;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileSectionHeader(title: title, icon: Icons.auto_awesome_outlined),
        QeranSpacing.vs12,
        Wrap(
          spacing: QeranSpacing.s12,
          runSpacing: QeranSpacing.s12,
          children: chips
              .map(
                (label) =>
                    QeranChip(label: label, variant: QeranChipVariant.interest),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

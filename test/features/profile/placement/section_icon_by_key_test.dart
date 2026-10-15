import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/placement_model.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/qa_default_section.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/section_icons.dart';

import '../../../core/shipped_fonts_rig.dart';

/// TQ18 (Tariq; on each item, run 11): `categoryKey`, an English key set in
/// the dashboard (`other` always exists; null when unset). The section's icon
/// goes by the key its items send; by its name only while no item sends the
/// field (before his deploy); the default for null, `other` or a key we don't
/// know.
IconData _iconFor(Map<String, dynamic> item, {String name = 'القيم'}) =>
    sectionIconFor(
      PlacementModel.fromJson({
        'placementCode': 0,
        'placementName': name,
        'items': [
          {'questionId': 1, ...item},
        ],
      }).toEntity(),
    );

void main() {
  test('each live key has its icon', () {
    expect(_iconFor({'categoryKey': 'personal'}), Icons.badge_outlined);
    expect(_iconFor({'categoryKey': 'values'}), Icons.mosque_outlined);
    expect(_iconFor({'categoryKey': 'marriage'}), Icons.diversity_1_outlined);
    expect(_iconFor({'categoryKey': 'work'}), Icons.work_outline_rounded);
    expect(_iconFor({'categoryKey': 'about'}), Icons.sticky_note_2_outlined);
    expect(_iconFor({'categoryKey': 'personality'}), Icons.psychology_outlined);
  });

  test('the key wins over the name', () {
    final icon = _iconFor({'categoryKey': 'work'}, name: 'القيم ونمط الحياة');
    expect(icon, Icons.work_outline_rounded);
  });

  test(
    'null, other and an unknown key take the default, whatever the name',
    () {
      for (final key in [null, 'other', 'religion', 'education', '']) {
        expect(
          _iconFor({'categoryKey': key}, name: 'القيم ونمط الحياة'),
          Icons.list_alt_rounded,
          reason: 'categoryKey: $key',
        );
      }
    },
  );

  test('the key is read whatever its case or spaces', () {
    expect(_iconFor({'categoryKey': ' Values '}), Icons.mosque_outlined);
  });

  test('no categoryKey in the payload: the name decides, as before', () {
    expect(_iconFor({}, name: 'القيم ونمط الحياة'), Icons.mosque_outlined);
    expect(_iconFor({}, name: 'قسم جديد'), Icons.list_alt_rounded);
  });
  testWidgets('the section draws the icon of its key', (tester) async {
    final placement = PlacementModel.fromJson({
      'placementCode': 0,
      'placementName': 'القيم ونمط الحياة',
      'items': [
        {'questionId': 1, 'categoryKey': 'work'},
      ],
    }).toEntity();
    final section = Placement(
      code: placement.code,
      name: placement.name,
      categoryKey: placement.categoryKey,
      hasCategoryKey: placement.hasCategoryKey,
      items: const [
        PlacementItem(
          questionId: 1,
          question: 'الديانة',
          type: PlacementItemType.select,
          value: PlacementSingle('مسلم'),
          display: PlacementSingle('مسلم'),
        ),
      ],
    );

    await pumpOnPhone(tester, 'ar', QaDefaultSection(placement: section));

    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mosque_outlined), findsNothing);
  });
}

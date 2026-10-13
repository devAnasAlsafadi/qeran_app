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

/// TQ18 (Tariq, 2026-10-13): each category carries `categoryKey`, an English
/// key set in the dashboard (`other` always exists; null when unset). The
/// section's icon goes by the key; by its name only while the payload has no
/// such field (before his deploy); the default for null, `other` or a key we
/// don't know.
IconData _iconFor(Map<String, dynamic> extra, {String name = 'الدين'}) =>
    sectionIconFor(
      PlacementModel.fromJson({
        'placementCode': 0,
        'placementName': name,
        'items': const [],
        ...extra,
      }).toEntity(),
    );

void main() {
  test('each proposed key has its icon', () {
    expect(_iconFor({'categoryKey': 'personal'}), Icons.badge_outlined);
    expect(_iconFor({'categoryKey': 'religion'}), Icons.mosque_outlined);
    expect(_iconFor({'categoryKey': 'marriage'}), Icons.diversity_1_outlined);
    expect(_iconFor({'categoryKey': 'work'}), Icons.work_outline_rounded);
    expect(_iconFor({'categoryKey': 'education'}), Icons.school_outlined);
  });

  test('the key wins over the name', () {
    final icon = _iconFor({
      'categoryKey': 'education',
    }, name: 'الدين ونمط الحياة');
    expect(icon, Icons.school_outlined);
  });

  test(
    'null, other and an unknown key take the default, whatever the name',
    () {
      for (final key in [null, 'other', 'hobbies', '']) {
        expect(
          _iconFor({'categoryKey': key}, name: 'الدين ونمط الحياة'),
          Icons.list_alt_rounded,
          reason: 'categoryKey: $key',
        );
      }
    },
  );

  test('the key is read whatever its case or spaces', () {
    expect(_iconFor({'categoryKey': ' Religion '}), Icons.mosque_outlined);
  });

  test('no categoryKey in the payload: the name decides, as before', () {
    expect(_iconFor({}, name: 'الدين ونمط الحياة'), Icons.mosque_outlined);
    expect(_iconFor({}, name: 'قسم جديد'), Icons.list_alt_rounded);
  });
  testWidgets('the section draws the icon of its key', (tester) async {
    final placement = PlacementModel.fromJson({
      'placementCode': 0,
      'placementName': 'الدين ونمط الحياة',
      'categoryKey': 'education',
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

    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mosque_outlined), findsNothing);
  });
}

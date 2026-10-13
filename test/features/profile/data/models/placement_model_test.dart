import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/placement_model.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';

void main() {
  group('PlacementModel — parsing', () {
    test('default group with single-value text item', () {
      final entity = PlacementModel.fromJson({
        'placement': 'default',
        'placementCode': 0,
        'placementName': 'المعلومات الشخصية',
        'items': [
          {
            'questionId': 5,
            'question': 'ما هو طولك؟',
            'type': 'height',
            'value': '175',
            'display': '175',
          },
        ],
      }).toEntity();

      expect(entity.code, PlacementCode.defaultGroup);
      expect(entity.name, 'المعلومات الشخصية');
      expect(entity.items, hasLength(1));
      expect(entity.items.first.type, PlacementItemType.height);
      expect(entity.items.first.display, isA<PlacementSingle>());
      expect(
        (entity.items.first.display as PlacementSingle).value,
        '175',
      );
    });

    test('interests placement with multi-value display', () {
      final entity = PlacementModel.fromJson({
        'placement': 'interests',
        'placementCode': 5,
        'placementName': 'الاهتمامات',
        'items': [
          {
            'questionId': 23,
            'question': 'اهتماماتها',
            'type': 'interests',
            'value': ['Travel', 'Reading'],
            'display': ['🧭 محبّة للسفر', '📚 قارئة'],
          },
        ],
      }).toEntity();

      expect(entity.code, PlacementCode.interests);
      expect(entity.items.first.type, PlacementItemType.interests);
      expect(entity.items.first.display, isA<PlacementMulti>());
      expect(
        (entity.items.first.display as PlacementMulti).values,
        ['🧭 محبّة للسفر', '📚 قارئة'],
      );
    });

    test('unknown placementCode falls back to defaultGroup', () {
      final entity = PlacementModel.fromJson({
        'placement': 'future_code',
        'placementCode': 99,
        'placementName': 'مجموعة جديدة',
        'items': const [],
      }).toEntity();
      expect(entity.code, PlacementCode.defaultGroup);
    });

    test('missing items array → empty list, not crash', () {
      final entity = PlacementModel.fromJson({
        'placementCode': 2,
        'placementName': 'نبذة',
      }).toEntity();
      expect(entity.code, PlacementCode.aboutMe);
      expect(entity.items, isEmpty);
    });

    // TQ18: the category's dashboard key, and whether the payload sends it.
    test('categoryKey: set, null, or not sent at all', () {
      Placement parse(Map<String, dynamic> extra) => PlacementModel.fromJson({
            'placementCode': 0,
            'placementName': 'الدين ونمط الحياة',
            ...extra,
          }).toEntity();

      final set = parse({'categoryKey': 'religion'});
      expect((set.categoryKey, set.hasCategoryKey), ('religion', true));
      final unset = parse({'categoryKey': null});
      expect((unset.categoryKey, unset.hasCategoryKey), (null, true));
      final before = parse({});
      expect((before.categoryKey, before.hasCategoryKey), (null, false));
    });
  });
}

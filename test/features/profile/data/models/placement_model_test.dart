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

    // TQ18, run 11: the key comes on each item; the section takes the first
    // key its items send, and knows whether any item sends the field.
    test('categoryKey from the items: set, null, or not sent at all', () {
      Placement parse(List<Map<String, dynamic>> items) =>
          PlacementModel.fromJson({
            'placementCode': 0,
            'placementName': 'القيم ونمط الحياة',
            'items': items,
          }).toEntity();

      final set = parse([
        {'questionId': 1, 'categoryKey': 'values'},
      ]);
      expect((set.categoryKey, set.hasCategoryKey), ('values', true));
      final unset = parse([
        {'questionId': 1, 'categoryKey': null},
      ]);
      expect((unset.categoryKey, unset.hasCategoryKey), (null, true));
      final before = parse([
        {'questionId': 1},
      ]);
      expect((before.categoryKey, before.hasCategoryKey), (null, false));
      final first = parse([
        {'questionId': 1, 'categoryKey': null},
        {'questionId': 2},
        {'questionId': 3, 'categoryKey': ' '},
        {'questionId': 4, 'categoryKey': 'values'},
        {'questionId': 5, 'categoryKey': 'work'},
      ]);
      expect((first.categoryKey, first.hasCategoryKey), ('values', true));
    });

    test('a categoryKey on the placement itself is not read', () {
      final placement = PlacementModel.fromJson({
        'placementCode': 0,
        'placementName': 'القيم ونمط الحياة',
        'categoryKey': 'work',
        'items': [
          {'questionId': 1},
        ],
      }).toEntity();

      expect(
        (placement.categoryKey, placement.hasCategoryKey),
        (null, false),
      );
    });
  });
}

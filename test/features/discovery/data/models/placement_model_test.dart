import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/data/models/placement_model.dart';
import 'package:qeran/features/discovery/domain/entities/placement_code.dart';

void main() {
  group('PlacementModel.tryParse', () {
    test('maps placementCode 1 → aboveImage and preserves name', () {
      final m = PlacementModel.tryParse({
        'placement': 'aboveImage',
        'placementCode': 1,
        'placementName': 'فوق الصورة',
        'items': const [],
      });
      expect(m, isNotNull);
      expect(m!.code, PlacementCode.aboveImage);
      expect(m.name, 'فوق الصورة');
      expect(m.items, isEmpty);
    });

    test('maps placementCode 0 → defaultGroup', () {
      final m = PlacementModel.tryParse({
        'placementCode': 0,
        'placementName': 'الحياة الزوجية',
        'items': const [],
      });
      expect(m!.code, PlacementCode.defaultGroup);
      expect(m.name, 'الحياة الزوجية');
    });

    test('unknown placementCode → null (dropped) + warning logged', () {
      final m = PlacementModel.tryParse({
        'placementCode': 99,
        'placementName': 'New thing',
        'items': const [],
      });
      expect(m, isNull);
    });

    test('parses nested items', () {
      final m = PlacementModel.tryParse({
        'placementCode': 5,
        'placementName': 'الاهتمامات',
        'items': [
          {
            'questionId': 22,
            'question': 'الصفات الشخصية',
            'type': 'interests',
            'value': ['Funny', 'Ambitious'],
            'display': ['😄 مرح', '🎯 طموح'],
          },
        ],
      });
      expect(m!.items.length, 1);
      expect(m.items.first.questionId, 22);
      expect(m.items.first.typeRaw, 'interests');
    });

    test('toEntity preserves all fields', () {
      final m = PlacementModel.tryParse({
        'placementCode': 2,
        'placementName': 'نبذة عني',
        'items': const [],
      });
      final entity = m!.toEntity();
      expect(entity.code, PlacementCode.aboutMe);
      expect(entity.name, 'نبذة عني');
      expect(entity.items, isEmpty);
    });
  });
}

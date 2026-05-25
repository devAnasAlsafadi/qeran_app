import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/data/models/discovery_page_model.dart';
import 'package:qeran/features/discovery/domain/entities/placement_code.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';

/// Minimal slice of the real `/api/Discovery` response — exercises every
/// placement code and both polymorphic value shapes (String + List).
Map<String, dynamic> _sample() => {
      'data': [
        {
          'id': 'profile-1',
          'name': 'anas',
          'age': 30,
          'images': [
            {
              'id': 'img-1',
              'url': '/api/users/profile-images/img-1',
              'isProfile': true,
              'isBlurred': true,
            },
          ],
          'matchingScore': 56.52,
          'placements': [
            {
              'placement': 'aboveImage',
              'placementCode': 1,
              'placementName': 'فوق الصورة',
              'items': [
                {
                  'questionId': 9,
                  'question': 'مكان الإقامة',
                  'type': 'select',
                  'value': 'SaudiArabia',
                  'display': 'السعودية',
                },
              ],
            },
            {
              'placement': 'interests',
              'placementCode': 5,
              'placementName': 'الاهتمامات',
              'items': [
                {
                  'questionId': 22,
                  'question': 'الصفات الشخصية',
                  'type': 'interests',
                  'value': ['Funny', 'Family'],
                  'display': ['😄 مرح', '👨‍👩‍👧 عائلي'],
                },
              ],
            },
            {
              'placement': 'unknown',
              'placementCode': 99,
              'placementName': 'should be dropped',
              'items': const [],
            },
          ],
        },
      ],
      'pageNumber': 1,
      'pageSize': 10,
      'totalCount': 1,
      'totalPages': 1,
    };

void main() {
  group('DiscoveryPageModel.fromJson', () {
    test('parses pagination fields', () {
      final m = DiscoveryPageModel.fromJson(_sample());
      expect(m.pageNumber, 1);
      expect(m.pageSize, 10);
      expect(m.totalCount, 1);
      expect(m.totalPages, 1);
    });

    test('parses one profile with images and matching score', () {
      final m = DiscoveryPageModel.fromJson(_sample());
      expect(m.profiles.length, 1);
      final p = m.profiles.first;
      expect(p.id, 'profile-1');
      expect(p.name, 'anas');
      expect(p.age, 30);
      expect(p.matchingScore, closeTo(56.52, 0.001));
      expect(p.images.length, 1);
      expect(p.images.first.url, contains('/api/users/profile-images/img-1'));
    });

    test('drops placements with unknown placementCode', () {
      final m = DiscoveryPageModel.fromJson(_sample());
      // Sample has 3 placements; one has code 99 and must be dropped.
      expect(m.profiles.first.placements.length, 2);
      expect(
        m.profiles.first.placements.map((p) => p.code),
        containsAll(<PlacementCode>[
          PlacementCode.aboveImage,
          PlacementCode.interests,
        ]),
      );
    });

    test('toEntity produces a usable DiscoveryPage with mapped types', () {
      final entity = DiscoveryPageModel.fromJson(_sample()).toEntity();
      expect(entity.hasMore, isFalse);
      final p = entity.profiles.first;
      final above = p.placements.firstWhere(
        (pl) => pl.code == PlacementCode.aboveImage,
      );
      expect(above.items.first.type, PlacementItemType.select);
      expect(
        above.items.first.display,
        equals(const PlacementSingle('السعودية')),
      );

      final interests = p.placements.firstWhere(
        (pl) => pl.code == PlacementCode.interests,
      );
      final displayValue = interests.items.first.display;
      expect(displayValue, isA<PlacementMulti>());
      expect(
        (displayValue as PlacementMulti).values,
        ['😄 مرح', '👨‍👩‍👧 عائلي'],
      );
    });

    test('hasMore is true when pageNumber < totalPages', () {
      final entity = DiscoveryPageModel.fromJson({
        ..._sample(),
        'pageNumber': 1,
        'totalPages': 3,
      }).toEntity();
      expect(entity.hasMore, isTrue);
    });
  });
}

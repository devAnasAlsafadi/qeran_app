import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/data/models/discovery_page_model.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_empty_reason.dart';
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

  // `reason` explains an EMPTY deck. It is absent from every page that carries
  // profiles, and absent entirely from a backend predating the field, so the
  // parse has to treat "not there" as ordinary rather than exceptional.
  group('empty reason', () {
    DiscoveryEmptyReason? reasonFrom(Map<String, dynamic> overrides) =>
        DiscoveryPageModel.fromJson({..._sample(), ...overrides})
            .toEntity()
            .reason;

    test('SEEN_ALL parses', () {
      expect(reasonFrom({'reason': 'SEEN_ALL'}), DiscoveryEmptyReason.seenAll);
    });

    test('NO_MATCHES_FOR_FILTERS parses', () {
      expect(
        reasonFrom({'reason': 'NO_MATCHES_FOR_FILTERS'}),
        DiscoveryEmptyReason.noMatchesForFilters,
      );
    });

    test('an absent field is null, not unknown', () {
      // The pre-`reason` backend, and every page that carries profiles.
      expect(reasonFrom(const {}), isNull);
    });

    test('an explicit null is null', () {
      expect(reasonFrom({'reason': null}), isNull);
    });

    test('a blank string is null', () {
      expect(reasonFrom({'reason': '   '}), isNull);
    });

    // A reason added server-side after this build shipped must degrade to the
    // generic empty state, never throw.
    test('an unrecognised name becomes unknown', () {
      expect(
        reasonFrom({'reason': 'PAUSED_FOR_MAINTENANCE'}),
        DiscoveryEmptyReason.unknown,
      );
    });

    test('casing drift still resolves', () {
      expect(reasonFrom({'reason': 'seen_all'}), DiscoveryEmptyReason.seenAll);
    });

    test('a non-string does not throw', () {
      expect(reasonFrom({'reason': 42}), DiscoveryEmptyReason.unknown);
    });

    test('a page carrying profiles parses fine with no reason', () {
      final page = DiscoveryPageModel.fromJson(_sample()).toEntity();
      expect(page.profiles, isNotEmpty);
      expect(page.reason, isNull);
    });
  });
}

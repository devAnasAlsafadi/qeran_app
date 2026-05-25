import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/other_profile_model.dart';

void main() {
  group('OtherProfileModel — parsing', () {
    test('happy path mirrors backend doc sample', () {
      final entity = OtherProfileModel.fromJson({
        'id': 'guid-of-noor',
        'name': 'نور',
        'age': 27,
        'matchingScore': 78.5,
        'images': [
          {
            'id': 'guid',
            'url': '/api/users/profile-images/guid',
            'isProfile': true,
            'isBlurred': true,
          },
        ],
        'placements': [
          {
            'placement': 'default',
            'placementCode': 0,
            'placementName': 'المعلومات الشخصية',
            'items': const [],
          },
        ],
      }).toEntity();

      expect(entity.id, 'guid-of-noor');
      expect(entity.name, 'نور');
      expect(entity.age, 27);
      expect(entity.matchingScore, 78.5);
      expect(entity.images, hasLength(1));
      expect(entity.images.first.isBlurred, isTrue);
      expect(entity.images.first.url, startsWith('http'));
      expect(entity.placements, hasLength(1));
    });

    test('isBlurred defaults to true when omitted', () {
      final entity = OtherProfileModel.fromJson({
        'id': 'x',
        'name': 'y',
        'images': [
          {'id': 'i1', 'url': '/api/users/profile-images/i1', 'isProfile': true},
        ],
        'placements': const [],
      }).toEntity();
      expect(entity.images.first.isBlurred, isTrue);
    });

    test('null age survives parsing', () {
      final entity = OtherProfileModel.fromJson({
        'id': 'x',
        'name': 'y',
        'age': null,
        'images': const [],
        'placements': const [],
      }).toEntity();
      expect(entity.age, isNull);
    });
  });
}

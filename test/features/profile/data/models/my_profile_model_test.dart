import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/my_profile_model.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

void main() {
  group('MyProfileModel — parsing', () {
    test('happy path with full payload', () {
      final entity = MyProfileModel.fromJson({
        'userId': 'my-guid',
        'name': 'أحمد',
        'email': 'ahmed@example.com',
        'gender': 'ذكر',
        'birthDate': '1995-08-12T00:00:00Z',
        'age': 30,
        'profileStatus': 'Visible',
        'hasAnsweredQuestions': true,
        'profileImage': {
          'id': 'guid',
          'url': '/api/users/profile-images/guid',
          'isProfile': true,
          'isApproved': true,
        },
        'images': [
          {
            'id': 'guid1',
            'url': '/api/users/profile-images/guid1',
            'isProfile': true,
            'isApproved': true,
          },
          {
            'id': 'guid2',
            'url': '/api/users/profile-images/guid2',
            'isProfile': false,
            'isApproved': false,
          },
        ],
        'placements': const [],
      }).toEntity();

      expect(entity.id, 'my-guid');
      expect(entity.email, 'ahmed@example.com');
      expect(entity.birthDate, isNotNull);
      expect(entity.age, 30);
      expect(entity.profileStatus, ProfileStatus.visible);
      expect(entity.hasAnsweredQuestions, isTrue);
      expect(entity.profileImage, isNotNull);
      expect(entity.profileImage!.isApproved, isTrue);
      expect(entity.images, hasLength(2));
      expect(entity.images[1].isApproved, isFalse);
      expect(entity.images.first.url, startsWith('http'));
    });

    test('PendingReview status', () {
      final entity = MyProfileModel.fromJson({
        'userId': 'guid',
        'profileStatus': 'PendingReview',
        'images': const [],
        'placements': const [],
      }).toEntity();
      expect(entity.profileStatus, ProfileStatus.pendingReview);
    });

    test('falls back to id when userId is missing', () {
      final entity = MyProfileModel.fromJson({
        'id': 'legacy-shape',
        'images': const [],
        'placements': const [],
      }).toEntity();
      expect(entity.id, 'legacy-shape');
    });
  });
}

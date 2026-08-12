import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/models/like_profile_image_model.dart';
import 'package:qeran/features/likes/data/models/match_image_model.dart';

/// The backend now ships server-rendered blurred variants alongside the
/// original. Absence must be distinguishable from presence, because absence is
/// what selects the client-side fallback.
void main() {
  const origin = 'https://qeranadmin-001-site1.rtempurl.com';

  group('LikeProfileImageModel', () {
    test('resolves both renditions against the origin', () {
      final entity = LikeProfileImageModel.fromJson({
        'id': 'i1',
        'url': '/api/users/profile-images/i1',
        'isProfile': true,
        'isBlurred': true,
        'blurredUrl': '/api/users/profile-images/i1/blurred',
        'blurredThumbnailUrl': '/api/users/profile-images/i1/blurred-thumb',
      }).toEntity();

      expect(entity.blurredUrl, '$origin/api/users/profile-images/i1/blurred');
      expect(
        entity.blurredThumbnailUrl,
        '$origin/api/users/profile-images/i1/blurred-thumb',
      );
    });

    test('an absolute rendition url is left alone', () {
      final entity = LikeProfileImageModel.fromJson({
        'id': 'i1',
        'url': '/x',
        'blurredUrl': 'https://cdn.test/b.jpg',
      }).toEntity();

      expect(entity.blurredUrl, 'https://cdn.test/b.jpg');
    });

    test('missing, null and empty renditions all read as absent', () {
      // Null is what selects the client-side blur fallback, so an empty
      // string must not masquerade as a usable url.
      for (final payload in <Map<String, dynamic>>[
        {'id': 'i1', 'url': '/x'},
        {'id': 'i1', 'url': '/x', 'blurredUrl': null},
        {'id': 'i1', 'url': '/x', 'blurredUrl': '   '},
      ]) {
        final entity = LikeProfileImageModel.fromJson(payload).toEntity();
        expect(entity.blurredUrl, isNull, reason: '$payload');
        expect(entity.blurredThumbnailUrl, isNull, reason: '$payload');
      }
    });
  });

  group('MatchImageModel', () {
    test('carries the renditions through to the entity', () {
      final entity = MatchImageModel.fromJson({
        'id': 'm1',
        'url': '/api/users/profile-images/m1',
        'isProfile': true,
        'isBlurred': true,
        'blurredUrl': '/api/users/profile-images/m1/blurred',
      }).toEntity();

      expect(entity.blurredUrl, '$origin/api/users/profile-images/m1/blurred');
      expect(entity.blurredThumbnailUrl, isNull);
      expect(entity.url, '$origin/api/users/profile-images/m1');
    });

    test('a pre-migration payload still parses, blurred and without a url', () {
      // Old responses omit the fields entirely; isBlurred must keep its
      // privacy-safe default so nothing is shown clear by accident.
      final entity = MatchImageModel.fromJson({
        'id': 'm1',
        'url': '/api/users/profile-images/m1',
      }).toEntity();

      expect(entity.isBlurred, isTrue);
      expect(entity.blurredUrl, isNull);
    });
  });
}

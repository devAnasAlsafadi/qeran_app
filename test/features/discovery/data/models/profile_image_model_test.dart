import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/discovery/data/models/profile_image_model.dart';

void main() {
  group('ProfileImageModel.fromJson', () {
    test('resolves relative URL to absolute server origin', () {
      final m = ProfileImageModel.fromJson({
        'id': 'abc',
        'url': '/api/users/profile-images/abc',
        'isProfile': true,
        'isBlurred': true,
      });
      final origin = Uri.parse(EndPoints.baseUrl).origin;
      expect(m.url, '$origin/api/users/profile-images/abc');
      expect(m.id, 'abc');
      expect(m.isProfile, true);
      expect(m.isBlurred, true);
    });

    test('preserves an already-absolute http URL', () {
      final m = ProfileImageModel.fromJson({
        'id': 'x',
        'url': 'http://cdn.example.com/x.jpg',
        'isProfile': false,
        'isBlurred': false,
      });
      expect(m.url, 'http://cdn.example.com/x.jpg');
    });

    test('defaults are safe for partial payloads', () {
      final m = ProfileImageModel.fromJson(const {});
      expect(m.id, '');
      // Empty path resolves to the bare origin — defensive, not pretty,
      // but it doesn't crash.
      expect(m.url.startsWith('http://'), isTrue);
      expect(m.isProfile, false);
      expect(m.isBlurred, false);
    });
  });
}

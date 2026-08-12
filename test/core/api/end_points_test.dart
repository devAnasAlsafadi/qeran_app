import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';

void main() {
  group('EndPoints.absoluteUrl', () {
    test('joins server origin with a server-relative path', () {
      // baseUrl ends with `/api/`. A relative path starting with `/api/`
      // must not produce a doubled `/api/api/` segment.
      final url = EndPoints.absoluteUrl(
        '/api/users/profile-images/abc-123',
      );
      expect(
        url,
        'https://qeranadmin-001-site1.rtempurl.com'
        '/api/users/profile-images/abc-123',
      );
    });

    test('passes through absolute http:// URLs', () {
      const original = 'http://cdn.example.com/img.jpg';
      expect(EndPoints.absoluteUrl(original), original);
    });

    test('passes through absolute https:// URLs', () {
      const original = 'https://cdn.example.com/img.jpg';
      expect(EndPoints.absoluteUrl(original), original);
    });

    test('inserts the missing separator on a slash-less path', () {
      final url = EndPoints.absoluteUrl('users/profile-images/x');
      // Gluing the path straight onto the origin would produce the host
      // `rtempurl.comusers`, which resolves to nothing and surfaces only as
      // a broken image. The separator is added instead.
      expect(
        url,
        'https://qeranadmin-001-site1.rtempurl.com/users/profile-images/x',
      );
    });
  });
}

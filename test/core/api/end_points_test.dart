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
        'http://qeranadmin-001-site1.rtempurl.com'
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

    test('handles a path without a leading slash', () {
      final url = EndPoints.absoluteUrl('users/profile-images/x');
      // Origin has no trailing slash; the path has no leading slash —
      // joined as-is. The server is unlikely to ship this shape, but
      // the helper must not corrupt it.
      expect(
        url,
        'http://qeranadmin-001-site1.rtempurl.comusers/profile-images/x',
      );
    });
  });
}

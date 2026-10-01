import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/api_image_headers.dart';
import 'package:qeran/core/api/end_points.dart';

const _token = 'jwt-123';
const _bearer = {'Authorization': 'Bearer $_token'};

void main() {
  final host = Uri.parse(EndPoints.baseUrl).host;

  group('our own origin gets the token', () {
    test('a Community image, resolved from its relative path', () {
      final url = EndPoints.absoluteUrl('/api/community/media/m-1/thumbnail');
      expect(imageHeadersFor(url, token: _token), _bearer);
    });

    test('a matchmaker avatar, host written in capitals', () {
      final url = 'https://${host.toUpperCase()}/api/community/avatars/u-1';
      expect(imageHeadersFor(url, token: _token), _bearer);
    });
  });

  group('no other host gets it (W5, W9)', () {
    final foreign = {
      'a signed video poster':
          'https://vz-abc.b-cdn.net/v-1/thumbnail.jpg?token=x',
      'mock media':
          'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
      'a look-alike subdomain': 'https://$host.evil.example/api/x',
      'our host as user info': 'https://$host@evil.example/api/x',
      'our host over plain http': 'http://$host/api/x',
      'plain http, even on port 443': 'http://$host:443/api/x',
      'our host on another port': 'https://$host:8443/api/x',
      'a relative path': '/api/community/media/m-1',
      'not a URL': '::',
    };
    for (final MapEntry(key: what, value: url) in foreign.entries) {
      test(what, () => expect(imageHeadersFor(url, token: _token), isNull));
    }
  });

  test('signed out: no headers, even on our origin', () {
    final url = EndPoints.absoluteUrl('/api/community/avatars/u-1');
    expect(imageHeadersFor(url, token: null), isNull);
    expect(imageHeadersFor(url, token: ''), isNull);
  });
}

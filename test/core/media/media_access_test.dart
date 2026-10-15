import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/media/media_access.dart';

Future<String?> _failing(String code) => guardMediaAccess<String?>(
  () async => throw PlatformException(code: code),
  fallback: null,
);

Matcher _refused(MediaAccess access) =>
    throwsA(isA<MediaAccessDenied>().having((e) => e.access, 'access', access));

/// Every picker call in both apps goes through this guard: the plugin's
/// refusal codes say which access is off; nothing else surfaces.
void main() {
  test('the camera refused: denied, or restricted on iOS', () async {
    await expectLater(
      _failing('camera_access_denied'),
      _refused(MediaAccess.camera),
    );
    await expectLater(
      _failing('camera_access_restricted'),
      _refused(MediaAccess.camera),
    );
  });

  test('the photos refused: denied, or restricted on iOS', () async {
    await expectLater(
      _failing('photo_access_denied'),
      _refused(MediaAccess.photos),
    );
    await expectLater(
      _failing('photo_access_restricted'),
      _refused(MediaAccess.photos),
    );
  });

  test('any other platform error reads as backing out', () async {
    expect(await _failing('no_available_camera'), isNull);
    expect(
      await guardMediaAccess<List<String>>(
        () async => throw PlatformException(code: 'already_active'),
        fallback: const [],
      ),
      isEmpty,
    );
  });

  test('a pick, or backing out, passes through untouched', () async {
    expect(
      await guardMediaAccess<String?>(() async => '/a.jpg', fallback: null),
      '/a.jpg',
    );
    expect(
      await guardMediaAccess<String?>(() async => null, fallback: '/x'),
      isNull,
    );
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/media/video_compress_adapter.dart';
import 'package:qeran/features/community/domain/ports/video_compressor.dart';

import 'video_compress_test_rig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final rig = VideoChannelRig();
  setUp(rig.setUp);
  tearDown(rig.tearDown);

  final android = VideoCompressAdapter(platform: TargetPlatform.android);
  final ios = VideoCompressAdapter(platform: TargetPlatform.iOS);

  group('Android: the stored size, swapped by the package for 0° and 180°', () {
    test('a portrait clip stored 1920 × 1080 at 90° is 1080 × 1920, with its '
        'length and the file\'s own size', () async {
      final path = rig.file('VID_portrait.mp4', 2048);
      rig.infos[path] = mediaJson(
        path,
        width: 1920,
        height: 1080,
        orientation: 90,
        duration: 30500,
      );

      expect(
        await android.inspect(path),
        const VideoFileInfo(
          duration: Duration(milliseconds: 30500),
          width: 1080,
          height: 1920,
          sizeBytes: 2048,
        ),
      );
    });

    test('a landscape clip at 0°, which the package answers as 1080 × 1920, '
        'is 1920 × 1080', () async {
      final path = rig.file('VID_landscape.mp4', 10);
      rig.infos[path] = mediaJson(
        path,
        width: 1080,
        height: 1920,
        orientation: 0,
      );

      final info = await android.inspect(path);

      expect((info?.width, info?.height), (1920, 1080));
    });

    test('no rotation read: the size as answered', () async {
      final path = rig.file('VID_plain.mp4', 10);
      rig.infos[path] = mediaJson(path, width: 1280, height: 720);

      final info = await android.inspect(path);

      expect((info?.width, info?.height), (1280, 720));
    });
  });

  test('iOS: the size is already as she sees it, and its orientation (a '
      'quarter turn off) is not used; fractional milliseconds round', () async {
    final portrait = rig.file('IMG_0001.MOV', 10);
    final landscape = rig.file('IMG_0002.MOV', 10);
    rig.infos[portrait] = mediaJson(
      portrait,
      width: 1080,
      height: 1920,
      orientation: 270,
      duration: 12345.678,
    );
    rig.infos[landscape] = mediaJson(
      landscape,
      width: 1920,
      height: 1080,
      orientation: 90,
    );

    final vertical = await ios.inspect(portrait);
    final wide = await ios.inspect(landscape);

    expect((vertical?.width, vertical?.height), (1080, 1920));
    expect(vertical?.duration, const Duration(milliseconds: 12346));
    expect((wide?.width, wide?.height), (1920, 1080));
  });

  test('unreadable: the plugin\'s error (Android), an empty answer (iOS), a '
      'file that is gone: null', () async {
    final broken = rig.file('notes.txt', 10);
    final empty = rig.file('audio.m4a', 10);
    final gone = '${broken}_gone.mp4';
    rig.infos[empty] = {};
    rig.infos[gone] = mediaJson(gone, width: 1280, height: 720);

    expect(await android.inspect(broken), isNull);
    expect(await ios.inspect(empty), isNull);
    expect(await android.inspect(gone), isNull);
  });
}

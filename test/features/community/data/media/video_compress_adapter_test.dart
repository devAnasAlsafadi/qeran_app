import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/media/video_compress_adapter.dart';
import 'package:qeran/features/community/domain/ports/video_compressor.dart';
import 'package:video_compress/video_compress.dart';

import 'video_compress_test_rig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final rig = VideoChannelRig();
  setUp(rig.setUp);
  tearDown(rig.tearDown);

  final adapter = VideoCompressAdapter(platform: TargetPlatform.android);

  test('answers the copy\'s path and facts, reports progress from 0 to 1, '
      'and asks for 1280 × 720 with the audio, keeping the original', () async {
    final source = rig.file('IMG_0001.MOV', 5000);
    final out = rig.file('VID_out.mp4', 1200);
    final seen = <double>[];

    final result = adapter.compress(source, onProgress: seen.add);
    await pumpEventQueue();
    await rig.tick(25.0);
    await rig.tick('50.5');
    rig.finish(mediaJson(out, width: 1280, height: 720, orientation: 90));

    expect(
      await result,
      CompressedVideo(
        path: out,
        info: const VideoFileInfo(
          duration: Duration(seconds: 30),
          width: 720,
          height: 1280,
          sizeBytes: 1200,
        ),
      ),
    );
    expect(seen, [0.25, 0.505]);
    expect(rig.compressions.single.arguments, {
      'path': source,
      'quality': VideoQuality.Res1280x720Quality.index,
      'deleteOrigin': false,
      'startTime': null,
      'duration': null,
      'includeAudio': true,
      'frameRate': 30,
    });
  });

  test('her cancel: UploadCancelledException at once, the phone told to '
      'stop, and no progress after it', () async {
    final cancel = UploadCancel();
    final seen = <double>[];
    rig.onCancel = () => rig.finish(null);

    final result = adapter.compress(
      rig.file('IMG_0001.MOV', 10),
      onProgress: seen.add,
      cancel: cancel,
    );
    final cancelled = expectLater(
      result,
      throwsA(isA<UploadCancelledException>()),
    );
    await pumpEventQueue();
    await rig.tick(40.0);
    cancel.cancel();
    await rig.tick(41.0);

    await cancelled;
    await pumpEventQueue();
    expect(rig.methods, contains('cancelCompression'));
    expect(seen, [0.4]);
  });

  test('a cancel before it starts never reaches the phone', () async {
    final cancel = UploadCancel()..cancel();

    final result = adapter.compress(rig.file('a.mp4', 10), cancel: cancel);

    await expectLater(result, throwsA(isA<UploadCancelledException>()));
    await pumpEventQueue();
    expect(rig.calls, isEmpty);
  });

  test('a failed compression: Android\'s null, iOS\'s empty answer (no file '
      'written), its stray isCancel: null', () async {
    final source = rig.file('a.mp4', 10);

    final failed = adapter.compress(source);
    await pumpEventQueue();
    rig.finish(null);
    expect(await failed, isNull);

    final empty = adapter.compress(source);
    await pumpEventQueue();
    rig.finish({'isCancel': false});
    expect(await empty, isNull);

    final stray = adapter.compress(source);
    await pumpEventQueue();
    rig.finish(mediaJson(source, width: 1, height: 1, isCancel: true));
    expect(await stray, isNull);
  });

  test('one at a time: after her cancel, the next compression waits for the '
      'phone to answer the first', () async {
    final cancel = UploadCancel();
    final first = adapter.compress(rig.file('a.mp4', 10), cancel: cancel);
    await pumpEventQueue();
    cancel.cancel();
    await expectLater(first, throwsA(isA<UploadCancelledException>()));

    final out = rig.file('out.mp4', 10);
    final second = adapter.compress(rig.file('b.mp4', 10));
    await pumpEventQueue();
    expect(rig.compressions, hasLength(1));

    rig.finish(null);
    await pumpEventQueue();
    expect(rig.compressions, hasLength(2));
    rig.finish(mediaJson(out, width: 1280, height: 720));
    expect((await second)?.path, out);
  });

  test('a tick that came after the last compression ended is not the next '
      'one\'s progress', () async {
    final source = rig.file('a.mp4', 10);
    final first = adapter.compress(source);
    await pumpEventQueue();
    rig.finish(null);
    await first;
    await rig.tick(100.0);
    final seen = <double>[];

    final second = adapter.compress(source, onProgress: seen.add);
    await pumpEventQueue();
    rig.finish(null);
    await second;

    expect(seen, isEmpty);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/entities/publish_event.dart';
import 'package:qeran/features/community/domain/entities/publish_session.dart';
import 'package:qeran/features/community/domain/usecases/video_preparation.dart';

import 'fake_video_compressor.dart';
import 'publish_rig.dart';

const _mb = 1024 * 1024;

PickedVideo _video(String path, {int bytes = 10 * _mb}) => PickedVideo(
  path: path,
  container: VideoContainer.quickTime,
  info: clip(bytes: bytes),
);

/// Her video made ready to go up (plan §3.4, D1, Q2, Q3).
void main() {
  late FakeCompressor compressor;
  late PublishSession session;
  late List<PublishEvent> events;
  setUp(() {
    compressor = FakeCompressor();
    session = PublishSession(newRequestId: () => 'req');
    events = [];
  });

  /// One attempt: its own cancel, as the use case begins each.
  Future<PickedVideo?> prepare(PickedVideo video, {int? maxBytes}) {
    final UploadCancel cancel = session.begin();
    return VideoPreparation(
      compressor,
      session,
      cancel,
      events.add,
    ).prepare(video, maxBytes: maxBytes);
  }

  test('compressed on the phone (D1): progress per whole percent from 0 to '
      '100, then the MP4 copy with its own facts', () async {
    final file = await prepare(_video('a.mov'));

    expect(describe(events), ['prep 0', 'prep 50', 'prep 100']);
    expect(file?.path, 'a.mov.mp4');
    expect(file?.container, VideoContainer.mp4);
    expect(file?.info.sizeBytes, 4 * _mb);
  });

  test('a retry doesn\'t compress it again, and reports nothing for it; '
      'another video is compressed', () async {
    final first = await prepare(_video('a.mov'));
    events.clear();

    expect(await prepare(_video('a.mov')), same(first));
    expect(events, isEmpty);
    await prepare(_video('b.mov'));
    expect(compressor.compressed, ['a.mov', 'b.mov']);
  });

  test('compression not available, or failed (Q2): the original as picked, '
      'kept for the retry too', () async {
    compressor.answer = (_) => null;
    final original = _video('a.mov');

    expect(await prepare(original), same(original));
    expect(describe(events), ['prep 0', 'prep 50', 'prep 100']);
    await prepare(original);
    expect(compressor.compressed, ['a.mov']);
  });

  test('her cancel while it compresses: the attempt ends there, and nothing '
      'is kept', () async {
    compressor.hold = Completer();
    final file = prepare(_video('a.mov'));
    await pumpEventQueue();

    session.cancel();

    expect(await file, isNull);
    expect(describe(events), ['prep 0', 'prep 50', 'cancelled']);
    expect(session.preparedVideo('a.mov'), isNull);
  });

  test('Q3: the file that would go up is held to config\'s size — the copy, '
      'or the original without compression; at the limit it goes', () async {
    expect(await prepare(_video('a.mov'), maxBytes: 4 * _mb), isNotNull);
    events.clear();
    expect(await prepare(_video('a.mov'), maxBytes: 4 * _mb - 1), isNull);
    expect(describe(events), ['refused a.mov tooLarge ${4 * _mb}']);

    compressor.answer = (_) => null;
    events.clear();
    expect(await prepare(_video('b.mov'), maxBytes: 5 * _mb), isNull);
    expect(describe(events).last, 'refused b.mov tooLarge ${10 * _mb}');
  });

  test('no size from config: the server checks alone (S19)', () async {
    compressor.answer = (_) => null;

    expect(await prepare(_video('a.mov', bytes: 500 * _mb)), isNotNull);
  });
}

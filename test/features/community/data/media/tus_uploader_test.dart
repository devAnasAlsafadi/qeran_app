import 'package:flutter_test/flutter_test.dart';

import 'tus_test_rig.dart';

void main() {
  late TusRig rig;
  setUp(() async {
    rig = TusRig();
    await rig.setUp();
  });
  tearDown(() => rig.tearDown());

  List<String?> patchOffsets() =>
      rig.sent('PATCH').map((r) => r.headers['upload-offset']).toList();

  test('create: an empty POST with the length, and the metadata as base64 '
      'of UTF-8; its relative Location is resolved and handed over', () async {
    await rig.upload();

    final create = rig.sent('POST').single;
    expect(create.url, TusRig.endpoint);
    expect(create.headers['tus-resumable'], '1.0.0');
    expect(create.headers['upload-length'], '10');
    expect(
      create.headers['upload-metadata'],
      'filetype dmlkZW8vbXA0,title 2YXZhti02YjYsQ==',
    );
    expect(create.contentLength, 0);
    expect(rig.created, [TusRig.uploadUrl]);
    expect(rig.sent('PATCH').map((r) => r.url).toSet(), {TusRig.uploadUrl});
  });

  test('the file in chunks, each at its offset, as octets', () async {
    await rig.upload();

    expect(patchOffsets(), ['0', '4', '8']);
    expect(rig.sent('PATCH').map((r) => r.headers['content-type']).toSet(), {
      'application/offset+octet-stream',
    });
    expect(rig.sent('PATCH').map((r) => r.headers['tus-resumable']).toSet(), {
      '1.0.0',
    });
    expect(rig.stored, rig.bytes);
  });

  test('each chunk starts at the offset the server gave back: one that '
      'kept less than it was sent gets the rest next', () async {
    rig.keepAtMost = 3;
    await rig.upload();

    expect(patchOffsets(), ['0', '3', '6', '9']);
    expect(rig.stored, rig.bytes);
  });

  test('progress moves within a chunk as the connection takes it, never '
      'back, and ends at the length', () async {
    const size = 200 * 1024;
    rig.videoOf(size);
    await rig.upload(chunkSize: 128 * 1024);

    final offsets = rig.progress.map((p) => p.$1).toList();
    expect(offsets.length, greaterThan(rig.sent('PATCH').length + 1));
    expect(offsets, [...offsets]..sort());
    expect(offsets.first, 0);
    expect(offsets.last, size);
    expect(rig.progress.map((p) => p.$2).toSet(), {size});
  });

  test('resume: HEAD gives the server\'s offset and it goes on from there, '
      'with no new upload', () async {
    rig.serverHas(6);
    await rig.upload(resumeAt: TusRig.uploadUrl);

    expect(rig.seen.map((r) => r.method), ['HEAD', 'PATCH']);
    expect(rig.sent('HEAD').single.url, TusRig.uploadUrl);
    expect(rig.sent('HEAD').single.headers['tus-resumable'], '1.0.0');
    expect(patchOffsets(), ['6']);
    expect(rig.created, isEmpty);
    expect(rig.progress.first, (6, 10));
    expect(rig.stored, rig.bytes);
  });

  for (final status in [404, 410, 403]) {
    test('resume, but HEAD says $status: the upload is gone, so a new one is '
        'created and handed over', () async {
      rig.headStatus = status;
      await rig.upload(resumeAt: Uri.parse('${TusRig.endpoint}/old'));

      expect(rig.seen.map((r) => r.method), [
        'HEAD',
        'POST',
        'PATCH',
        'PATCH',
        'PATCH',
      ]);
      expect(rig.created, [TusRig.uploadUrl]);
      expect(rig.stored, rig.bytes);
    });
  }

  test('resume when the server has it all: no PATCH, and progress says '
      'done', () async {
    rig.serverHas(10);
    await rig.upload(resumeAt: TusRig.uploadUrl);

    expect(rig.seen.map((r) => r.method), ['HEAD']);
    expect(rig.progress, [(10, 10)]);
  });

  group('a foreign origin', () {
    setUp(() async {
      rig.headStatus = 410;
      await rig.upload(resumeAt: TusRig.uploadUrl);
      expect(rig.seen.map((r) => r.method).toSet(), {'HEAD', 'POST', 'PATCH'});
    });

    test('no Authorization header on any request', () {
      for (final request in rig.seen) {
        expect(
          request.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('authorization')),
          reason: request.method,
        );
      }
    });

    test('the grant\'s headers, as given, on every request', () {
      for (final request in rig.seen) {
        for (final header in TusRig.grant.entries) {
          expect(
            request.headers[header.key],
            header.value,
            reason: '${request.method} ${header.key}',
          );
        }
      }
    });
  });
}

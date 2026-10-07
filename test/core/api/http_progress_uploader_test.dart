import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'upload_test_rig.dart';

void main() {
  late UploadRig rig;
  setUp(() async {
    rig = UploadRig();
    await rig.setUp();
  });
  tearDown(() => rig.tearDown());

  test('progress follows the bytes the connection takes, up to the whole '
      'body; the envelope comes back', () async {
    final progress = <(int, int)>[];
    final answer = await rig
        .uploader((request, body) async {
          await body.toBytes();
          return jsonAnswer(uploadOk);
        })
        .postFile(
          'community/media/images',
          fieldName: 'image',
          file: rig.file,
          onProgress: (s, t) => progress.add((s, t)),
        );

    expect(answer, uploadOk);
    expect(progress.length, greaterThan(3));
    final total = rig.sent!.contentLength!;
    expect(progress.map((p) => p.$2).toSet(), {total});
    expect(progress.last.$1, total);
    final sents = progress.map((p) => p.$1).toList();
    expect(sents, [...sents]..sort());
  });

  test('our headers, to our origin; the type and name are the caller\'s, '
      'never the file\'s extension', () async {
    late String body;
    await rig
        .uploader((request, stream) async {
          body = latin1.decode(await stream.toBytes());
          return jsonAnswer(uploadOk);
        })
        .postFile('community/media/images', fieldName: 'image', file: rig.file);

    final sent = rig.sent!;
    expect(sent.url.toString(), '${EndPoints.baseUrl}community/media/images');
    expect(sent.headers['authorization'], 'Bearer jwt-1');
    expect(sent.headers['accept-language'], 'ar');
    expect(sent.headers['content-type'], startsWith('multipart/form-data;'));
    expect(body, contains('name="image"; filename="image.jpg"'));
    expect(body, contains('content-type: image/jpeg'));
    expect(body, isNot(contains('heic')));
  });

  test('her cancel mid-upload stops it: UploadCancelledException', () async {
    final cancel = UploadCancel();
    final upload = rig
        .uploader((request, body) async {
          unawaited(body.first.then((_) => cancel.cancel()));
          return untilAborted(request);
        })
        .postFile('p', fieldName: 'image', file: rig.file, cancel: cancel);

    await expectLater(upload, throwsA(isA<UploadCancelledException>()));
  });

  test('cancelled before it started: nothing is sent', () async {
    final cancel = UploadCancel()..cancel();
    final upload = rig
        .uploader((request, body) async => jsonAnswer(uploadOk))
        .postFile('p', fieldName: 'image', file: rig.file, cancel: cancel);

    await expectLater(upload, throwsA(isA<UploadCancelledException>()));
    expect(rig.sent, isNull);
  });

  test('nothing moves for the stall time: a timeout', () async {
    final upload = rig
        .uploader(
          (request, body) => untilAborted(request),
          stall: const Duration(milliseconds: 50),
        )
        .postFile('p', fieldName: 'image', file: rig.file);

    await expectLater(
      upload,
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          LocaleKeys.errors_timeout,
        ),
      ),
    );
  });
}

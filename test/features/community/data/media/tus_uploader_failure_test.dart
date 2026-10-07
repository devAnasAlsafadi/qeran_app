import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../../core/api/upload_test_rig.dart' show untilAborted;
import 'tus_test_rig.dart';

Matcher serverError(String message, {int? status}) => throwsA(
  isA<ServerException>()
      .having((e) => e.message, 'message', message)
      .having((e) => e.statusCode, 'statusCode', status),
);

void main() {
  late TusRig rig;
  setUp(() async {
    rig = TusRig();
    await rig.setUp();
  });
  tearDown(() => rig.tearDown());

  test('her cancel mid-PATCH stops it: UploadCancelledException, and '
      'nothing more is sent', () async {
    final cancel = UploadCancel();
    rig.onPatch = (request, body) {
      unawaited(body.first.then((_) => cancel.cancel()));
      return untilAborted(request);
    };

    await expectLater(
      rig.upload(cancel: cancel),
      throwsA(isA<UploadCancelledException>()),
    );
    expect(rig.seen.map((r) => r.method), ['POST', 'PATCH']);
  });

  test('cancelled before it started: nothing is sent', () async {
    final cancel = UploadCancel()..cancel();

    await expectLater(
      rig.upload(cancel: cancel),
      throwsA(isA<UploadCancelledException>()),
    );
    expect(rig.seen, isEmpty);
  });

  test('a server that takes the chunk and never answers: a timeout once '
      'nothing moved for the stall time', () async {
    rig.onPatch = (request, body) async {
      await body.toBytes();
      return untilAborted(request);
    };

    await expectLater(
      rig.upload(stall: const Duration(milliseconds: 50)),
      serverError(LocaleKeys.errors_timeout),
    );
  });

  test('the connection drops mid-PATCH: OfflineException', () async {
    rig.onPatch = (request, body) async {
      await body.first;
      throw http.ClientException('Connection reset by peer', request.url);
    };

    await expectLater(rig.upload(), throwsA(isA<OfflineException>()));
  });

  test('a 500 on PATCH: ServerException, with its status', () async {
    rig.onPatch = (request, body) async {
      await body.drain<void>();
      return answer(500);
    };

    await expectLater(
      rig.upload(),
      serverError(LocaleKeys.errors_server, status: 500),
    );
  });

  test('a PATCH answer whose offset didn\'t move fails, rather than sending '
      'the same chunk forever', () async {
    rig.onPatch = (request, body) async {
      await body.drain<void>();
      return answer(204, {'upload-offset': '0'});
    };

    await expectLater(
      rig.upload(),
      serverError(LocaleKeys.errors_generic, status: 204),
    );
    expect(rig.sent('PATCH'), hasLength(1));
  });

  test('HEAD failing otherwise than "gone" is a failure: no new upload is '
      'created behind it', () async {
    rig.headStatus = 500;

    await expectLater(
      rig.upload(resumeAt: TusRig.uploadUrl),
      serverError(LocaleKeys.errors_server, status: 500),
    );
    expect(rig.seen.map((r) => r.method), ['HEAD']);
  });
}

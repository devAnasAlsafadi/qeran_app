import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/api/http_progress_uploader.dart';
import 'package:qeran/core/api/http_request_context.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockLanguage extends Mock implements LanguageService {}

class _MockConnectivity extends Mock implements ConnectivityService {}

typedef _Handler =
    Future<http.StreamedResponse> Function(
      http.BaseRequest request,
      http.ByteStream body,
    );

http.StreamedResponse _json(Object body, {int status = 200}) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

/// Waits for the request's abort, then throws what `IOClient` throws.
Future<http.StreamedResponse> _untilAborted(http.BaseRequest request) async {
  await (request as http.Abortable).abortTrigger;
  throw http.RequestAbortedException(request.url);
}

void main() {
  late _MockConnectivity connectivity;
  late Directory dir;
  late File picked;
  http.BaseRequest? sent;

  const ok = {
    'status': 1,
    'data': {'mediaId': 'm-1'},
  };

  setUp(() async {
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    dir = await Directory.systemTemp.createTemp('upload_test');
    // A HEIC name with JPEG inside, as the Android picker returns it.
    picked = File('${dir.path}/scaled_IMG.heic')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, ...List.filled(200 * 1024, 7)]);
    sent = null;
  });
  tearDown(() => dir.delete(recursive: true));

  HttpProgressUploader uploader(_Handler handler, {Duration? stall}) {
    final storage = _MockStorage();
    final language = _MockLanguage();
    when(
      () => storage.get<String>(StorageKeys.token),
    ).thenAnswer((_) async => 'jwt-1');
    when(() => language.currentLanguage).thenReturn('ar');
    return HttpProgressUploader(
      client: MockClient.streaming((request, body) {
        sent = request;
        return handler(request, body);
      }),
      context: HttpRequestContext(
        storage: storage,
        languageService: language,
        connectivity: connectivity,
      ),
      stallTimeout: stall ?? const Duration(seconds: 30),
    );
  }

  UploadFile file() => UploadFile(
    path: picked.path,
    fileName: 'image.jpg',
    contentType: 'image/jpeg',
  );

  test('progress follows the bytes the connection takes, up to the whole '
      'body; the envelope comes back', () async {
    final progress = <(int, int)>[];
    final answer =
        await uploader((request, body) async {
          await body.toBytes();
          return _json(ok);
        }).postFile(
          'community/media/images',
          fieldName: 'image',
          file: file(),
          onProgress: (s, t) => progress.add((s, t)),
        );

    expect(answer, ok);
    expect(progress.length, greaterThan(3));
    final total = sent!.contentLength!;
    expect(progress.map((p) => p.$2).toSet(), {total});
    expect(progress.last.$1, total);
    final sents = progress.map((p) => p.$1).toList();
    expect(sents, [...sents]..sort());
  });

  test('our headers, to our origin; the type and name are the caller\'s, '
      'never the file\'s extension', () async {
    late String body;
    await uploader((request, stream) async {
      body = latin1.decode(await stream.toBytes());
      return _json(ok);
    }).postFile('community/media/images', fieldName: 'image', file: file());

    expect(sent!.url.toString(), '${EndPoints.baseUrl}community/media/images');
    expect(sent!.headers['authorization'], 'Bearer jwt-1');
    expect(sent!.headers['accept-language'], 'ar');
    expect(sent!.headers['content-type'], startsWith('multipart/form-data;'));
    expect(body, contains('name="image"; filename="image.jpg"'));
    expect(body, contains('content-type: image/jpeg'));
    expect(body, isNot(contains('heic')));
  });

  test('her cancel mid-upload stops it: UploadCancelledException', () async {
    final cancel = UploadCancel();
    final upload = uploader((request, body) async {
      unawaited(body.first.then((_) => cancel.cancel()));
      return _untilAborted(request);
    }).postFile('p', fieldName: 'image', file: file(), cancel: cancel);

    await expectLater(upload, throwsA(isA<UploadCancelledException>()));
  });

  test('cancelled before it started: nothing is sent', () async {
    final cancel = UploadCancel()..cancel();
    final upload = uploader(
      (request, body) async => _json(ok),
    ).postFile('p', fieldName: 'image', file: file(), cancel: cancel);

    await expectLater(upload, throwsA(isA<UploadCancelledException>()));
    expect(sent, isNull);
  });

  test('nothing moves for the stall time: a timeout', () async {
    final upload = uploader(
      (request, body) => _untilAborted(request),
      stall: const Duration(milliseconds: 50),
    ).postFile('p', fieldName: 'image', file: file());

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

  test('offline: OfflineException before anything is sent', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    final upload = uploader(
      (request, body) async => _json(ok),
    ).postFile('p', fieldName: 'image', file: file());

    await expectLater(upload, throwsA(isA<OfflineException>()));
    expect(sent, isNull);
  });

  test('a dropped connection is offline', () async {
    final upload = uploader(
      (request, body) async => throw const SocketException('reset'),
    ).postFile('p', fieldName: 'image', file: file());

    await expectLater(upload, throwsA(isA<OfflineException>()));
  });

  test('the server\'s code comes through', () async {
    final upload = uploader((request, body) async {
      await body.toBytes();
      return _json({'status': 0, 'errorCode': 'MEDIA_TOO_LARGE'}, status: 400);
    }).postFile('p', fieldName: 'image', file: file());

    await expectLater(
      upload,
      throwsA(
        isA<CodedServerException>().having(
          (e) => e.errorCode,
          'errorCode',
          'MEDIA_TOO_LARGE',
        ),
      ),
    );
  });
}

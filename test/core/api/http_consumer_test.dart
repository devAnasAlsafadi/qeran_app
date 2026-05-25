import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class MockClient extends Mock implements http.Client {}

class MockStorage extends Mock implements StorageService {}

class MockLanguageService extends Mock implements LanguageService {}

class _FakeBaseRequest extends Fake implements http.BaseRequest {}

http.StreamedResponse _streamed(String body, int status) {
  return http.StreamedResponse(
    Stream.fromIterable([utf8.encode(body)]),
    status,
    // Without an explicit charset, http.Response.fromStream defaults to
    // ISO-8859-1 and mangles Arabic copy.
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBaseRequest());
  });

  late MockClient client;
  late MockStorage storage;
  late MockLanguageService language;
  late HttpConsumer consumer;
  late Directory tmpDir;
  late File tmpFile;

  setUp(() async {
    client = MockClient();
    storage = MockStorage();
    language = MockLanguageService();

    when(() => storage.get<String>(StorageKeys.token))
        .thenAnswer((_) async => 'jwt-1');
    when(() => language.currentLanguage).thenReturn('ar');

    consumer = HttpConsumer(
      client: client,
      storage: storage,
      languageService: language,
    );

    tmpDir = await Directory.systemTemp.createTemp('hc_test_');
    tmpFile = File('${tmpDir.path}/sample.jpg');
    await tmpFile.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('postMultipart', () {
    test(
      'builds MultipartRequest with correct method, URL, fieldName, files, '
      'and extra fields',
      () async {
        when(() => client.send(any())).thenAnswer((_) async {
          return _streamed('{"status":1,"message":"OK"}', 200);
        });

        final result = await consumer.postMultipart(
          'users/profile-images',
          files: [tmpFile],
          fieldName: 'images',
          fields: const {'primary': '0'},
        );

        final captured = verify(() => client.send(captureAny())).captured.single
            as http.MultipartRequest;
        expect(captured.method, 'POST');
        expect(
          captured.url.toString(),
          '${EndPoints.baseUrl}users/profile-images',
        );
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'images');
        expect(captured.fields['primary'], '0');
        expect(result, isA<Map<String, dynamic>>());
      },
    );

    test('attaches Authorization and Accept-Language from DI', () async {
      when(() => client.send(any()))
          .thenAnswer((_) async => _streamed('{"status":1}', 200));

      await consumer.postMultipart(
        'p',
        files: [tmpFile],
        fieldName: 'images',
      );

      final captured = verify(() => client.send(captureAny())).captured.single
          as http.MultipartRequest;
      expect(captured.headers['Authorization'], 'Bearer jwt-1');
      expect(captured.headers['Accept-Language'], 'ar');
    });

    test('omits Content-Type so multipart can set its own with boundary',
        () async {
      when(() => client.send(any()))
          .thenAnswer((_) async => _streamed('{"status":1}', 200));

      await consumer.postMultipart(
        'p',
        files: [tmpFile],
        fieldName: 'images',
      );

      final captured = verify(() => client.send(captureAny())).captured.single
          as http.MultipartRequest;
      // Multipart will set this on send; what we MUST NOT do is leave the
      // 'application/json' that _getHeaders adds.
      expect(captured.headers['Content-Type'], isNot('application/json'));
    });

    test('empty files list throws ArgumentError', () {
      expect(
        () => consumer.postMultipart(
          'p',
          files: const [],
          fieldName: 'images',
        ),
        throwsArgumentError,
      );
    });

    test(
      'non-2xx response with no server message → ServerException with '
      'status-mapped key',
      () async {
        // No `message` / `error` field → _handleResponse falls back to the
        // status-code → localized-key mapping (parity with get/post/etc.).
        when(() => client.send(any()))
            .thenAnswer((_) async => _streamed('{}', 401));

        expect(
          () => consumer.postMultipart(
            'p',
            files: [tmpFile],
            fieldName: 'images',
          ),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              equals(LocaleKeys.errors_unauthorized),
            ),
          ),
        );
      },
    );

    test(
      'non-2xx response with server message → ServerException carries the '
      'server-supplied message',
      () async {
        when(() => client.send(any()))
            .thenAnswer((_) async => _streamed('{"message":"الصورة كبيرة"}', 413));

        expect(
          () => consumer.postMultipart(
            'p',
            files: [tmpFile],
            fieldName: 'images',
          ),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              equals('الصورة كبيرة'),
            ),
          ),
        );
      },
    );

    test('honors a caller-provided timeout', () async {
      when(() => client.send(any())).thenAnswer((_) async {
        // Sleep longer than the timeout to force a TimeoutException.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _streamed('{"status":1}', 200);
      });

      expect(
        () => consumer.postMultipart(
          'p',
          files: [tmpFile],
          fieldName: 'images',
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}

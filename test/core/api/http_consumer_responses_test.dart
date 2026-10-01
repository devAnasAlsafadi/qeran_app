import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockLanguage extends Mock implements LanguageService {}

class _MockConnectivity extends Mock implements ConnectivityService {}

/// Answers every request with [status] + [body], or throws [error]; records
/// the last request so its method, headers and body can be checked.
class _ScriptedClient extends http.BaseClient {
  int status = 200;
  String body = '';
  Object? error;
  http.Request? last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    last = request as http.Request;
    if (error case final Object e) throw e;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

Matcher coded({String? code, int? status, String? message}) =>
    isA<CodedServerException>()
        .having((e) => e.errorCode, 'errorCode', code)
        .having((e) => e.statusCode, 'statusCode', status)
        .having((e) => e.message, 'message', message ?? anything);

void main() {
  late _ScriptedClient client;
  late _MockConnectivity connectivity;
  late HttpConsumer consumer;

  setUp(() {
    client = _ScriptedClient();
    final storage = _MockStorage();
    final language = _MockLanguage();
    connectivity = _MockConnectivity();
    when(() => storage.get<String>(StorageKeys.token))
        .thenAnswer((_) async => 'jwt-1');
    when(() => language.currentLanguage).thenReturn('ar');
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    consumer = HttpConsumer(
      client: client,
      storage: storage,
      languageService: language,
      connectivity: connectivity,
    );
  });

  void reply(int status, Object? json) {
    client.status = status;
    client.body = json is String ? json : jsonEncode(json);
  }

  group('enveloped verbs', () {
    test('status 1 returns the whole envelope; headers carry token and language',
        () async {
      reply(200, {'status': 1, 'message': '', 'data': {'id': 7}});

      final body = await consumer.get('x', queryParameters: {'page': 2});

      expect(body, {'status': 1, 'message': '', 'data': {'id': 7}});
      expect(client.last!.url.queryParameters, {'page': '2'});
      expect(client.last!.headers['Authorization'], 'Bearer jwt-1');
      expect(client.last!.headers['Accept-Language'], 'ar');
    });

    test('status 0 on a 2xx throws its errorCode and message, no status',
        () async {
      reply(200, {'status': 0, 'message': 'لا', 'errorCode': 'X_CODE'});

      await expectLater(consumer.post('x'),
          throwsA(coded(code: 'X_CODE', message: 'لا')));
    });

    test('a coded non-2xx keeps its errorCode but not its status', () async {
      reply(429, {'status': 0, 'message': 'كثير', 'errorCode': 'RATE_LIMITED'});

      await expectLater(consumer.post('x'),
          throwsA(coded(code: 'RATE_LIMITED', message: 'كثير')));
    });

    test('a bodiless 429 is the too-many-requests message, uncoded', () async {
      reply(429, '');

      await expectLater(
        consumer.get('x'),
        throwsA(isA<ServerException>()
            .having((e) => e is CodedServerException, 'coded', isFalse)
            .having((e) => e.message, 'message',
                LocaleKeys.errors_too_many_requests)),
      );
    });

    test("a validation error's first message wins", () async {
      reply(400, {
        'errors': {
          'Text': ['النص مطلوب'],
        },
      });

      await expectLater(consumer.put('x'), throwsA(coded(message: 'النص مطلوب')));
    });

    test('a non-JSON 500 is the server message', () async {
      reply(500, '<html>');

      await expectLater(
        consumer.delete('x'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', LocaleKeys.errors_server)),
      );
    });

    test('put and patch encode a null body as JSON null; post sends none',
        () async {
      reply(200, {'status': 1});

      await consumer.put('x');
      expect(client.last!.body, 'null');
      await consumer.patch('x');
      expect(client.last!.body, 'null');
      await consumer.post('x');
      expect(client.last!.body, isEmpty);
    });
  });

  group('raw verbs', () {
    test('a non-2xx keeps its transport status, even with an empty body',
        () async {
      reply(404, '');

      await expectLater(
        consumer.getRaw('x'),
        throwsA(coded(status: 404, message: LocaleKeys.errors_not_found)),
      );
    });

    test('2xx: the body as-is (a status 0 envelope too), null when empty',
        () async {
      reply(200, {'status': 0, 'errorCode': 'E'});
      expect(await consumer.postRaw('x'), {'status': 0, 'errorCode': 'E'});

      reply(200, '');
      expect(await consumer.getRaw('x'), isNull);
    });

    test('success: false throws its message and code', () async {
      reply(200, {'success': false, 'message': 'm', 'errorCode': 'E'});

      await expectLater(
          consumer.postRaw('x'), throwsA(coded(code: 'E', message: 'm')));
    });
  });

  group('transport', () {
    test('offline before the request: OfflineException, nothing sent', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      await expectLater(consumer.get('x'), throwsA(isA<OfflineException>()));
      expect(client.last, isNull);
    });

    test('a socket error is offline; a timeout is the timeout message',
        () async {
      client.error = const SocketException('down');
      await expectLater(consumer.post('x'), throwsA(isA<OfflineException>()));

      client.error = TimeoutException('slow');
      await expectLater(
        consumer.getRaw('x'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', LocaleKeys.errors_timeout)),
      );
    });
  });
}

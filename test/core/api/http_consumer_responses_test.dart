import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'http_test_rig.dart';

Matcher coded({String? code, int? status, String? message}) =>
    isA<CodedServerException>()
        .having((e) => e.errorCode, 'errorCode', code)
        .having((e) => e.statusCode, 'statusCode', status)
        .having((e) => e.message, 'message', message ?? anything);

void main() {
  late ScriptedClient client;
  late MockConnectivity connectivity;
  late HttpConsumer consumer;

  setUp(() {
    client = ScriptedClient();
    connectivity = MockConnectivity();
    consumer = scriptedConsumer(client, connectivity: connectivity);
  });

  void reply(int status, Object? json) => client.reply(status, json);

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

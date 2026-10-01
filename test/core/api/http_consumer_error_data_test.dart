import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';

import 'http_test_rig.dart';

Matcher withData(Object? data) =>
    throwsA(isA<CodedServerException>().having((e) => e.data, 'data', data));

void main() {
  late ScriptedClient client;
  late HttpConsumer consumer;

  setUp(() {
    client = ScriptedClient();
    consumer = scriptedConsumer(client, connectivity: MockConnectivity());
  });

  const wait = {'retryAfterSeconds': 42};

  test("an enveloped 429 keeps the envelope's data", () async {
    client.reply(429, {
      'status': 0,
      'message': 'كثير',
      'errorCode': 'RATE_LIMITED',
      'data': wait,
    });

    await expectLater(consumer.post('x'), withData(wait));
  });

  test('a status 0 on a 2xx keeps it too', () async {
    client.reply(200, {'status': 0, 'errorCode': 'OTP_COOLDOWN', 'data': wait});

    await expectLater(consumer.post('x'), withData(wait));
  });

  test('the raw path keeps it, with the status', () async {
    client.reply(429, {'errorCode': 'RATE_LIMITED', 'data': wait});

    await expectLater(
      consumer.postRaw('x'),
      throwsA(isA<CodedServerException>()
          .having((e) => e.data, 'data', wait)
          .having((e) => e.statusCode, 'statusCode', 429)),
    );
  });

  test('success: false keeps it', () async {
    client.reply(200, {'success': false, 'message': 'm', 'data': wait});

    await expectLater(consumer.getRaw('x'), withData(wait));
  });

  test('no data in the body, or no body: null', () async {
    client.reply(400, {'status': 0, 'errorCode': 'VALIDATION_ERROR'});
    await expectLater(consumer.post('x'), withData(null));

    client.reply(404, '');
    await expectLater(consumer.getRaw('x'), withData(null));
  });
}

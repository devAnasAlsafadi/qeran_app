import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'http_test_rig.dart';

/// R7: a failure envelope with no message used to carry the English literal
/// "Operation Failed", which any data source that doesn't classify showed as
/// is. It's the app's own generic key now, so the screen translates it.
void main() {
  late ScriptedClient client;
  late HttpConsumer consumer;

  setUp(() {
    client = ScriptedClient();
    consumer = scriptedConsumer(client, connectivity: MockConnectivity());
  });

  Matcher genericKey() => isA<CodedServerException>().having(
    (e) => e.message,
    'message',
    LocaleKeys.errors_generic,
  );

  test('a status 0 on a 2xx with no message is the generic key', () async {
    client.reply(200, {'status': 0, 'errorCode': 'X_CODE'});

    await expectLater(consumer.post('x'), throwsA(genericKey()));
  });

  test('success: false with no message is the generic key', () async {
    client.reply(200, {'success': false});

    await expectLater(consumer.postRaw('x'), throwsA(genericKey()));
  });
}

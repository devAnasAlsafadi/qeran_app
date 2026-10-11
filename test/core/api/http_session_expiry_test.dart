import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'http_test_rig.dart';
import 'upload_test_rig.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockLanguage extends Mock implements LanguageService {}

/// C4 (TQ11): a 401 to our Bearer is reported with the token it carried, from
/// every way a request leaves, and its empty body is never a parse error. A
/// 403 is a permission error: the generic text, and never a report.
void main() {
  late ScriptedClient client;
  late SessionExpiry expiry;
  late List<String> reports;

  setUp(() {
    client = ScriptedClient();
    expiry = SessionExpiry();
    reports = [];
    expiry.reports.listen(reports.add);
  });

  HttpConsumer consumer({String? token = 'jwt-1'}) => scriptedConsumer(
    client,
    connectivity: MockConnectivity(),
    token: token,
    sessionExpiry: expiry,
  );

  /// The broadcast delivers on the next turn.
  Future<void> delivered() => Future<void>.delayed(Duration.zero);

  Matcher refused(String key, int status) => throwsA(
    isA<ServerException>()
        .having((e) => e.message, 'message', key)
        .having((e) => e.statusCode, 'statusCode', status),
  );

  test('an empty 401: «انتهت الجلسة», the status kept, the token '
      'reported', () async {
    client.reply(401, '');

    await expectLater(
      consumer().get('x'),
      refused(LocaleKeys.errors_unauthorized, 401),
    );
    await delivered();
    expect(reports, ['jwt-1']);
  });

  test('the raw path reports too', () async {
    client.reply(401, '');

    await expectLater(consumer().postRaw('x'), throwsA(isA<ServerException>()));
    await delivered();
    expect(reports, ['jwt-1']);
  });

  test('a request without a token never reports', () async {
    client.reply(401, '');

    await expectLater(consumer(token: null).get('x'), throwsA(anything));
    await delivered();
    expect(reports, isEmpty);
  });

  test('an empty token (a registration not yet verified) never '
      'reports', () async {
    client.reply(401, '');

    await expectLater(consumer(token: '').get('x'), throwsA(anything));
    await delivered();
    expect(reports, isEmpty);
  });

  test('a 403: the generic text, and no report', () async {
    client.reply(403, '');

    await expectLater(
      consumer().get('x'),
      refused(LocaleKeys.errors_generic, 403),
    );
    await delivered();
    expect(reports, isEmpty);
  });

  test('a multipart request reports', () async {
    final dir = await Directory.systemTemp.createTemp('expiry_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    final storage = _MockStorage();
    final language = _MockLanguage();
    final connectivity = MockConnectivity();
    when(
      () => storage.get<String>(StorageKeys.token),
    ).thenAnswer((_) async => 'jwt-1');
    when(() => language.currentLanguage).thenReturn('ar');
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    final multipart = HttpConsumer(
      client: MockClient((_) async => http.Response('', 401)),
      storage: storage,
      languageService: language,
      connectivity: connectivity,
      sessionExpiry: expiry,
    );

    await expectLater(
      multipart.postMultipart('x', files: [file], fieldName: 'f'),
      throwsA(isA<ServerException>()),
    );
    await delivered();
    expect(reports, ['jwt-1']);
  });

  test('the progress uploader reports', () async {
    final rig = UploadRig();
    await rig.setUp();
    addTearDown(rig.tearDown);
    final upload = rig
        .uploader((request, body) async {
          await body.toBytes();
          return http.StreamedResponse(const Stream.empty(), 401);
        }, expiry: expiry)
        .postFile('p', fieldName: 'image', file: rig.file);

    await expectLater(upload, throwsA(isA<ServerException>()));
    await delivered();
    expect(reports, ['jwt-1']);
  });
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/http_consumer.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/storage_service.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockLanguage extends Mock implements LanguageService {}

class MockConnectivity extends Mock implements ConnectivityService {}

/// Answers every request with [status] + [body], or throws [error]; records
/// the last request so its method, headers and body can be checked.
class ScriptedClient extends http.BaseClient {
  int status = 200;
  String body = '';
  Object? error;
  http.Request? last;

  void reply(int status, Object? json) {
    this.status = status;
    body = json is String ? json : jsonEncode(json);
  }

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

/// An [HttpConsumer] over [client]: signed in (`jwt-1`), Arabic, online —
/// unless the test flips [connectivity].
HttpConsumer scriptedConsumer(
  ScriptedClient client, {
  required MockConnectivity connectivity,
}) {
  final storage = _MockStorage();
  final language = _MockLanguage();
  when(() => storage.get<String>(StorageKeys.token))
      .thenAnswer((_) async => 'jwt-1');
  when(() => language.currentLanguage).thenReturn('ar');
  when(() => connectivity.isOnline).thenAnswer((_) async => true);
  return HttpConsumer(
    client: client,
    storage: storage,
    languageService: language,
    connectivity: connectivity,
  );
}

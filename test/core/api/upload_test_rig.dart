import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/http_progress_uploader.dart';
import 'package:qeran/core/api/http_request_context.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/storage_service.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockLanguage extends Mock implements LanguageService {}

class _MockConnectivity extends Mock implements ConnectivityService {}

typedef UploadHandler =
    Future<http.StreamedResponse> Function(
      http.BaseRequest request,
      http.ByteStream body,
    );

const uploadOk = {
  'status': 1,
  'data': {'mediaId': 'm-1'},
};

http.StreamedResponse jsonAnswer(Object body, {int status = 200}) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

/// Waits for the request's abort, then throws what `IOClient` throws.
Future<http.StreamedResponse> untilAborted(http.BaseRequest request) async {
  await (request as http.Abortable).abortTrigger;
  throw http.RequestAbortedException(request.url);
}

/// A picked file — a HEIC name with JPEG inside, as the Android picker
/// returns it — and an uploader over a scripted server: signed in
/// (`jwt-1`), Arabic, online unless [connectivity] says otherwise.
class UploadRig {
  final connectivity = _MockConnectivity();
  late final Directory _dir;
  late final File picked;

  /// The request the server saw, if any.
  http.BaseRequest? sent;

  Future<void> setUp() async {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    _dir = await Directory.systemTemp.createTemp('upload_test');
    picked = File('${_dir.path}/scaled_IMG.heic')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, ...List.filled(200 * 1024, 7)]);
  }

  Future<void> tearDown() => _dir.delete(recursive: true);

  UploadFile get file => UploadFile(
    path: picked.path,
    fileName: 'image.jpg',
    contentType: 'image/jpeg',
  );

  HttpProgressUploader uploader(UploadHandler handler, {Duration? stall}) {
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
}

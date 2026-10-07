import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/features/community/data/media/tus_uploader.dart';

typedef TusHandler =
    Future<http.StreamedResponse> Function(
      http.BaseRequest request,
      http.ByteStream body,
    );

http.StreamedResponse answer(
  int status, [
  Map<String, String> headers = const {},
]) => http.StreamedResponse(const Stream.empty(), status, headers: headers);

/// Bunny's tus endpoint, scripted and strict: a `PATCH` must start where the
/// server is (409 otherwise), and the server keeps all of it, or at most
/// [keepAtMost] bytes. `HEAD` answers with what it has, or [headStatus]. The
/// video is a temp file of bytes `0, 1, 2, …`.
class TusRig {
  static final endpoint = Uri.parse('https://video.bunnycdn.com/tusupload');
  static final uploadUrl = Uri.parse(
    'https://video.bunnycdn.com/tusupload/vid-1',
  );
  static const grant = {
    'AuthorizationSignature': 'sig-1',
    'AuthorizationExpire': '1760000000',
    'VideoId': 'vid-1',
    'LibraryId': 'lib-1',
  };

  /// An Arabic title, so the metadata's UTF-8 shows.
  static const metadata = {'filetype': 'video/mp4', 'title': 'منشور'};

  late final Directory _dir;
  late File video;
  late List<int> bytes;

  /// Every request the server saw, in order.
  final seen = <http.BaseRequest>[];

  /// What the server has of the upload.
  final stored = <int>[];

  /// Each URL `onCreated` was given, and each progress report.
  final created = <Uri>[];
  final progress = <(int, int)>[];

  int headStatus = 200;
  int? keepAtMost;

  /// Replaces the server's answer to a `PATCH`, e.g. to fail one.
  TusHandler? onPatch;

  Future<void> setUp() async {
    _dir = await Directory.systemTemp.createTemp('tus_test');
    videoOf(10);
  }

  Future<void> tearDown() => _dir.delete(recursive: true);

  void videoOf(int size) {
    bytes = List.generate(size, (i) => i % 256);
    video = File('${_dir.path}/video.mp4')..writeAsBytesSync(bytes);
  }

  /// The upload at [uploadUrl] already has the file's first [count] bytes.
  void serverHas(int count) => stored
    ..clear()
    ..addAll(bytes.take(count));

  Iterable<http.BaseRequest> sent(String method) =>
      seen.where((r) => r.method == method);

  Future<void> upload({
    Uri? resumeAt,
    UploadCancel? cancel,
    int chunkSize = 4,
    Duration stall = const Duration(seconds: 30),
  }) =>
      TusUploader(
        client: MockClient.streaming(_serve),
        chunkSize: chunkSize,
        stallTimeout: stall,
      ).upload(
        path: video.path,
        length: bytes.length,
        endpoint: endpoint,
        headers: grant,
        metadata: metadata,
        resumeAt: resumeAt,
        onCreated: created.add,
        onProgress: (sent, total) => progress.add((sent, total)),
        cancel: cancel,
      );

  Future<http.StreamedResponse> _serve(
    http.BaseRequest request,
    http.ByteStream body,
  ) async {
    seen.add(request);
    return switch (request.method) {
      'POST' => _create(),
      'HEAD' => answer(headStatus, {'upload-offset': '${stored.length}'}),
      _ => (onPatch ?? _keep)(request, body),
    };
  }

  /// A new upload starts empty; its Location is relative, as Bunny's may be.
  http.StreamedResponse _create() {
    stored.clear();
    return answer(201, {'location': '/tusupload/vid-1'});
  }

  Future<http.StreamedResponse> _keep(
    http.BaseRequest request,
    http.ByteStream body,
  ) async {
    final chunk = await body.toBytes();
    if (request.headers['upload-offset'] != '${stored.length}') {
      return answer(409);
    }
    stored.addAll(chunk.take(keepAtMost ?? chunk.length));
    return answer(204, {'upload-offset': '${stored.length}'});
  }
}

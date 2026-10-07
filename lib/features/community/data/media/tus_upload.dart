import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:qeran/core/api/counting_request.dart';
import 'package:qeran/core/api/http_errors.dart';
import 'package:qeran/core/api/upload_abort.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The answers to `HEAD` that mean an earlier upload is gone, so a new one is
/// created: 404 and 410 as tus 1.0.0 has them, and 403 as well, which is not
/// confirmed against Bunny yet. If the grant itself is refused, the create
/// that follows fails on its own, with its own status.
const _gone = {403, 404, 410};

const _octets = 'application/offset+octet-stream';

/// One attempt at sending one file with tus 1.0.0 (plan §3.4, Q1): where the
/// upload stands on the server, and the requests that move it on. Every
/// request carries the grant's headers and tus's, and nothing of ours: Bunny
/// is a foreign origin, so no Bearer ever goes there.
class TusUpload {
  TusUpload({
    required this.client,
    required this.abort,
    required this.chunkSize,
    required this.path,
    required this.length,
    required this.endpoint,
    required this.headers,
    required this.metadata,
    this.resumeAt,
    this.onCreated,
    this.onProgress,
  });

  final http.Client client;
  final UploadAbort abort;
  final int chunkSize;
  final String path;
  final int length;
  final Uri endpoint;
  final Map<String, String> headers;
  final Map<String, String> metadata;
  final Uri? resumeAt;
  final void Function(Uri uploadUrl)? onCreated;
  final UploadProgress? onProgress;

  /// Goes on from [resumeAt] while the server still has it, or creates a new
  /// upload, then sends what the server doesn't have yet, one chunk per
  /// `PATCH`.
  Future<void> run() async {
    final (url, start) = await _start();
    onProgress?.call(start, length);
    var offset = start;
    while (offset < length) {
      offset = await _patch(url, offset);
    }
  }

  Future<(Uri, int)> _start() async {
    final earlier = resumeAt;
    if (earlier != null) {
      final offset = await _offsetAt(earlier);
      if (offset != null) return (earlier, offset);
    }
    final url = await _create();
    onCreated?.call(url);
    return (url, 0);
  }

  /// The offset the server has for [url], or null when that upload is gone.
  Future<int?> _offsetAt(Uri url) async {
    final request = http.AbortableRequest(
      'HEAD',
      url,
      abortTrigger: abort.trigger,
    )..headers.addAll(_with(const {}));
    final response = await _send(request);
    if (_gone.contains(response.statusCode)) {
      AppLogger.info(
        'HEAD (tus) $url gone: ${response.statusCode}',
        tag: 'HTTP',
      );
      return null;
    }
    return _offsetOf(_ok(response), atLeast: 0);
  }

  /// An empty `POST` with the length and the metadata. The answer's
  /// `Location`, which may be relative, is the new upload's URL.
  Future<Uri> _create() async {
    final request =
        http.AbortableRequest('POST', endpoint, abortTrigger: abort.trigger)
          ..headers.addAll(
            _with({
              'Upload-Length': '$length',
              if (metadata.isNotEmpty) 'Upload-Metadata': _encoded(metadata),
            }),
          );
    final response = _ok(await _send(request));
    final location = response.headers['location'];
    if (location == null) throw _malformed(response);
    return endpoint.resolve(location);
  }

  /// One chunk from [offset], streamed from the file as the connection takes
  /// it, so progress moves within the chunk too. Returns the server's new
  /// offset, never our own count: a server may keep less than it was sent.
  Future<int> _patch(Uri url, int offset) async {
    final end = min(offset + chunkSize, length);
    final request =
        CountingRequest(
            'PATCH',
            url,
            body: File(path).openRead(offset, end),
            length: end - offset,
            abortTrigger: abort.trigger,
            onSent: (sent) {
              abort.alive();
              onProgress?.call(offset + sent, length);
            },
          )
          ..headers.addAll(
            _with({'Upload-Offset': '$offset', 'Content-Type': _octets}),
          );
    return _offsetOf(_ok(await _send(request)), atLeast: offset + 1);
  }

  /// Sends [request] unless the upload was stopped meanwhile. An answer is
  /// movement too, for the stall clock.
  Future<http.Response> _send(http.BaseRequest request) async {
    abort.throwIfFired();
    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    abort.alive();
    return response;
  }

  /// The grant's headers as given (Bunny checks them on every request), then
  /// tus's on top.
  Map<String, String> _with(Map<String, String> tus) => {
    ...headers,
    'Tus-Resumable': '1.0.0',
    ...tus,
  };

  http.Response _ok(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return response;
    throw ServerException(
      message: statusErrorMessage(status),
      statusCode: status,
    );
  }

  /// `Upload-Offset`, from [atLeast] up to the length. Anything else would
  /// read past the file, or send the same chunk forever.
  int _offsetOf(http.Response response, {required int atLeast}) {
    final offset = int.tryParse(response.headers['upload-offset'] ?? '');
    if (offset == null || offset < atLeast || offset > length) {
      throw _malformed(response);
    }
    return offset;
  }

  ServerException _malformed(http.Response response) => ServerException(
    message: LocaleKeys.errors_generic,
    statusCode: response.statusCode,
  );
}

/// `Upload-Metadata`: comma-separated `key base64(value)` pairs, each value
/// as UTF-8 first, so an Arabic title arrives whole. An empty value is the
/// key alone, as tus allows.
String _encoded(Map<String, String> metadata) => metadata.entries
    .map(
      (e) => e.value.isEmpty
          ? e.key
          : '${e.key} ${base64.encode(utf8.encode(e.value))}',
    )
    .join(',');

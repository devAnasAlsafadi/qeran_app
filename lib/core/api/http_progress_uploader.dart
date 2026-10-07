import 'package:http/http.dart' as http;

import '../app_logger.dart';
import '../domain/upload.dart';
import '../errors/exceptions.dart';
import 'counting_request.dart';
import 'end_points.dart';
import 'http_errors.dart';
import 'http_request_context.dart';
import 'http_response_handler.dart';
import 'progress_uploader.dart';
import 'upload_abort.dart';

/// [ProgressUploader] over `http`: the multipart body is streamed through a
/// byte counter, and stops on her cancel or when nothing moves for
/// [stallTimeout]. There is no overall timeout, because a slow network that
/// is still sending isn't failing.
class HttpProgressUploader implements ProgressUploader {
  final http.Client client;
  final HttpRequestContext context;

  /// No byte taken and no answer for this long → a timeout.
  final Duration stallTimeout;

  HttpProgressUploader({
    required this.client,
    required this.context,
    this.stallTimeout = const Duration(seconds: 30),
  });

  @override
  Future<dynamic> postFile(
    String path, {
    required String fieldName,
    required UploadFile file,
    UploadProgress? onProgress,
    UploadCancel? cancel,
  }) async {
    final uri = Uri.parse('${EndPoints.baseUrl}$path');
    AppLogger.info('POST (upload) $uri', tag: 'HTTP');
    final abort = UploadAbort(cancel, stallTimeout);
    try {
      await context.ensureOnline();
      abort.throwIfFired();
      final request = await _request(uri, fieldName, file, abort, onProgress);
      final response = await http.Response.fromStream(
        await client.send(request),
      );
      return handleEnvelopedResponse(response);
    } catch (e) {
      throw abort.explain() ?? _transportError(e, uri);
    } finally {
      abort.dispose();
    }
  }

  /// The multipart body with the type and name the caller gave, under our
  /// headers. Multipart sets its own `Content-Type`, with the boundary.
  Future<CountingRequest> _request(
    Uri uri,
    String fieldName,
    UploadFile file,
    UploadAbort abort,
    UploadProgress? onProgress,
  ) async {
    final multipart = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: file.fileName,
          contentType: http.MediaType.parse(file.contentType),
        ),
      );
    final total = multipart.contentLength;
    final body = multipart.finalize();
    final headers = await context.headers()
      ..remove('Content-Type');
    return CountingRequest(
        'POST',
        uri,
        body: body,
        length: total,
        abortTrigger: abort.trigger,
        onSent: (sent) {
          abort.alive();
          onProgress?.call(sent, total);
        },
      )
      ..headers.addAll(headers)
      ..headers.addAll(multipart.headers);
  }

  Exception _transportError(Object e, Uri uri) {
    if (e is OfflineException ||
        e is ServerException ||
        e is UploadCancelledException) {
      return e as Exception;
    }
    if (isOfflineTransportError(e)) return const OfflineException();
    AppLogger.error('POST (upload) $uri failed', error: e, tag: 'HTTP');
    return ServerException(message: transportErrorMessage(e));
  }
}

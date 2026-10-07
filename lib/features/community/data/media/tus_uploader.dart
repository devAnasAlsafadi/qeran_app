import 'package:http/http.dart' as http;
import 'package:qeran/core/api/http_errors.dart';
import 'package:qeran/core/api/upload_abort.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';

import '../../domain/ports/resumable_uploader.dart';
import 'tus_upload.dart';

/// [ResumableUploader] over `http`: our own small tus 1.0.0 client rather
/// than `tus_client_dart`, which builds its own `http.Client` and was last
/// published three years ago (plan Q1). Like `HttpProgressUploader`, it
/// stops on her cancel or when nothing moves for [stallTimeout], with no
/// overall timeout: a slow network that is still sending isn't failing.
class TusUploader implements ResumableUploader {
  final http.Client client;

  /// Bytes per `PATCH`. A retry goes on from the server's offset, so a
  /// dropped connection costs at most the chunk in flight; each chunk costs
  /// a round trip.
  final int chunkSize;

  /// No byte taken and no answer for this long → a timeout.
  final Duration stallTimeout;

  TusUploader({
    required this.client,
    this.chunkSize = 4 * 1024 * 1024,
    this.stallTimeout = const Duration(seconds: 30),
  });

  @override
  Future<void> upload({
    required String path,
    required int length,
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, String> metadata,
    Uri? resumeAt,
    void Function(Uri uploadUrl)? onCreated,
    UploadProgress? onProgress,
    UploadCancel? cancel,
  }) => _stoppable(
    endpoint,
    cancel,
    (abort) => TusUpload(
      client: client,
      abort: abort,
      chunkSize: chunkSize,
      path: path,
      length: length,
      endpoint: endpoint,
      headers: headers,
      metadata: metadata,
      resumeAt: resumeAt,
      onCreated: onCreated,
      onProgress: onProgress,
    ).run(),
  );

  /// Runs [send] under one abort for the whole upload, and turns whatever
  /// it threw into the port's exceptions.
  Future<void> _stoppable(
    Uri endpoint,
    UploadCancel? cancel,
    Future<void> Function(UploadAbort abort) send,
  ) async {
    AppLogger.info('tus upload $endpoint', tag: 'HTTP');
    final abort = UploadAbort(cancel, stallTimeout);
    try {
      await send(abort);
    } catch (e) {
      throw abort.explain() ?? _transportError(e, endpoint);
    } finally {
      abort.dispose();
    }
  }

  Exception _transportError(Object e, Uri endpoint) {
    if (e is OfflineException ||
        e is ServerException ||
        e is UploadCancelledException) {
      return e as Exception;
    }
    if (isOfflineTransportError(e)) return const OfflineException();
    AppLogger.error('tus upload $endpoint failed', error: e, tag: 'HTTP');
    return ServerException(message: transportErrorMessage(e));
  }
}

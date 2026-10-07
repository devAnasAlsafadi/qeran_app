import 'package:qeran/core/domain/upload.dart';

/// Sends her post's video straight to Bunny Stream with tus 1.0.0, under the
/// grant from `POST community/media/videos` (contract §6.8). The file never
/// passes through our server, and a retry goes on from the server's offset
/// rather than from zero (plan §3.4, Q1).
abstract class ResumableUploader {
  /// Sends the file at [path] ([length] bytes) to [endpoint] with tus 1.0.0,
  /// with the grant's [headers] on every request and its [metadata] on the
  /// create. With [resumeAt] (an upload URL from an earlier attempt) it first
  /// asks `HEAD` for the offset and goes on from there; if that upload is
  /// gone (404, 410, 403) it creates a new one. [onCreated] gets a new
  /// upload's URL as soon as it exists, so the caller can keep it for a later
  /// retry. [onProgress] reports (offset, length).
  ///
  /// Throws `UploadCancelledException` once [cancel] fires,
  /// `OfflineException` offline, and a `ServerException` (a stall's timeout
  /// included) otherwise.
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
  });
}

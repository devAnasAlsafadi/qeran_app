import '../domain/upload.dart';

/// Sends one file to our API as `multipart/form-data`, reporting the bytes
/// as they go and stopping on cancel (plan §3.4). It sends our headers, to
/// our origin only. Kept apart from `ApiConsumer`, so that port's fakes stay
/// as they are.
abstract class ProgressUploader {
  /// POSTs [file] under [fieldName] to [path] (relative to the API base) and
  /// returns the envelope, as `ApiConsumer.post` does. Throws
  /// `UploadCancelledException` once [cancel] fires, `OfflineException`
  /// offline, and a `ServerException` (a stall's timeout included)
  /// otherwise.
  Future<dynamic> postFile(
    String path, {
    required String fieldName,
    required UploadFile file,
    UploadProgress? onProgress,
    UploadCancel? cancel,
  });
}

import 'dart:async';

/// One file to send. Its [fileName] and [contentType] are the caller's,
/// taken from the file's first bytes and never from its extension: a picked
/// HEIC can come back as `scaled_IMG.heic` with JPEG inside (plan §3.3).
class UploadFile {
  final String path;
  final String fileName;

  /// A MIME type, e.g. `image/jpeg`.
  final String contentType;

  const UploadFile({
    required this.path,
    required this.fileName,
    required this.contentType,
  });
}

/// Bytes sent so far, out of [total].
typedef UploadProgress = void Function(int sent, int total);

/// Stops an upload in flight: one handle per attempt, and cancelling twice
/// is harmless.
class UploadCancel {
  final _cancelled = Completer<void>();

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _cancelled.future;

  bool get isCancelled => _cancelled.isCompleted;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

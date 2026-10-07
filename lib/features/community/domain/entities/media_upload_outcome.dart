import 'media_refusal.dart';

/// Typed outcomes of uploading one of her media (6.7, 6.8), on the `Right`
/// as a publish's are. Everything else stays on the `Left`: the failed strip
/// (D3), or `UploadCancelledFailure` when she stopped it.
sealed class MediaUploadOutcome<T> {
  const MediaUploadOutcome();
}

/// Uploaded: [value] is what the next step needs (the `mediaId`, or the
/// video's upload grant).
final class MediaUploaded<T> extends MediaUploadOutcome<T> {
  final T value;
  const MediaUploaded(this.value);
}

/// The server's own check refused it.
final class MediaUploadRefused<T> extends MediaUploadOutcome<T> {
  final MediaRefusal refusal;
  const MediaUploadRefused(this.refusal);
}

/// `VIDEO_SERVICE_UNAVAILABLE` (BA-A6): try again in a little while.
final class MediaVideoUnavailable<T> extends MediaUploadOutcome<T> {
  const MediaVideoUnavailable();
}

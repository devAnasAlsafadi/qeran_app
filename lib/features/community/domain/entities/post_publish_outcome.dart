import 'community_post.dart';
import 'media_refusal.dart';

/// Typed outcomes of publishing her post (6.2). Lives on the `Right` of
/// `Either<Failure, PostPublishOutcome>`, as a comment's does; transport and
/// unmapped failures stay on the `Left` (the composer's failed strip, D3).
sealed class PostPublishOutcome {
  const PostPublishOutcome();
}

/// Made: `Published` for text or images (D5), `Processing` for a video (D4).
final class PostPublished extends PostPublishOutcome {
  final CommunityPost post;
  const PostPublished(this.post);
}

/// `CONTENT_NOT_ALLOWED` — the filter refused the text (BA-A7); the draft
/// stays so she can edit it.
final class PostRejected extends PostPublishOutcome {
  const PostRejected();
}

/// `COMMUNITY_GUIDELINES_NOT_ACCEPTED` — a new version came out while she
/// wrote: the guidelines run, then she publishes again (§3.1).
final class PostGuidelinesRequired extends PostPublishOutcome {
  const PostGuidelinesRequired();
}

/// `VIDEO_SERVICE_UNAVAILABLE` (BA-A6): the draft stays, and Retry keeps
/// the same request id.
final class PostVideoUnavailable extends PostPublishOutcome {
  const PostVideoUnavailable();
}

/// The server's own check refused her media (BA-A9, Q3, C10).
final class PostMediaRefused extends PostPublishOutcome {
  final MediaRefusal refusal;
  const PostMediaRefused(this.refusal);
}

/// `VALIDATION_ERROR` (C7): the app checks first, so this is the server's
/// backstop, e.g. a limit lowered since the composer read it.
final class PostTextInvalid extends PostPublishOutcome {
  const PostTextInvalid();
}

/// Her uploaded media failed or is gone (`MEDIA_UPLOAD_FAILED`,
/// `MEDIA_PROCESSING_FAILED`, `MEDIA_NOT_FOUND`, `MEDIA_NOT_READY`): the
/// failed strip (D3), and Retry uploads it again from the start.
final class PostMediaLost extends PostPublishOutcome {
  const PostMediaLost();
}

import 'community_post.dart';

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

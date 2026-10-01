import 'community_comment.dart';

/// Typed outcomes of sending a comment or a reply (contract §3.8, §3.9, §4).
/// Lives on the `Right` of `Either<Failure, CommentSubmitOutcome>`, as chat's
/// `SendTextOutcome` does; transport and unmapped failures stay on the `Left`.
sealed class CommentSubmitOutcome {
  const CommentSubmitOutcome();
}

final class CommentPosted extends CommentSubmitOutcome {
  final CommunityComment comment;
  const CommentPosted(this.comment);
}

/// `CONTENT_NOT_ALLOWED` — the filter refused it; the text goes back in the
/// field so it can be edited.
final class CommentFiltered extends CommentSubmitOutcome {
  const CommentFiltered();
}

/// `RATE_LIMITED` (5 a minute, 60 an hour) or a bare HTTP 429. [retryAfter]
/// is the server's `retryAfterSeconds` when it sent one.
final class CommentRateLimited extends CommentSubmitOutcome {
  final Duration? retryAfter;
  const CommentRateLimited({this.retryAfter});
}

/// `DISPLAY_NAME_REQUIRED` — the name step runs, then the member sends again.
final class CommentNameRequired extends CommentSubmitOutcome {
  const CommentNameRequired();
}

/// `COMMUNITY_GUIDELINES_NOT_ACCEPTED` — the guidelines run, then the member
/// sends again.
final class CommentGuidelinesRequired extends CommentSubmitOutcome {
  const CommentGuidelinesRequired();
}

/// `PROFILE_NOT_APPROVED` — read-only until the profile is approved.
final class CommentNotApproved extends CommentSubmitOutcome {
  const CommentNotApproved();
}

/// `COMMENT_NOT_FOUND` on a reply — the comment it answers is gone (deleted,
/// or hidden by a block).
final class CommentParentGone extends CommentSubmitOutcome {
  const CommentParentGone();
}

/// `POST_NOT_FOUND` — the post itself is gone.
final class CommentPostGone extends CommentSubmitOutcome {
  const CommentPostGone();
}

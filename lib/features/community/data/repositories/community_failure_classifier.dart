import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/retry_after.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/comment_submit_outcome.dart';
import '../../domain/entities/guidelines_acceptance.dart';
import '../error_codes.dart';

/// The server's `errorCode` on a failure, when it sent one.
String? communityErrorCode(Failure failure) =>
    failure is CodedServerFailure ? failure.errorCode : null;

/// An accept's answer (§4.1). A version that is no longer current comes
/// back as `VALIDATION_ERROR` — the one validation the call can fail.
Either<Failure, GuidelinesAcceptance> guidelinesAcceptanceOf(
  Either<Failure, void> result,
) => result.fold(
  (failure) =>
      communityErrorCode(failure) == CommunityErrorCodes.validationError
      ? const Right(GuidelinesAcceptance.outdated)
      : Left(failure),
  (_) => const Right(GuidelinesAcceptance.accepted),
);

/// Both shapes of "too many": the comment limit's `RATE_LIMITED` envelope
/// (HTTP 429), and a bare 429 — which `HttpConsumer` turns into the
/// `errors_too_many_requests` message, with no code and no status.
bool isCommunityRateLimited(Failure failure) {
  if (failure is CodedServerFailure &&
      (failure.errorCode == CommunityErrorCodes.rateLimited ||
          failure.statusCode == 429)) {
    return true;
  }
  return failure.message == LocaleKeys.errors_too_many_requests;
}

/// A comment or reply failure the member has a screen for, as a typed
/// outcome; null leaves it a generic failure (`VALIDATION_ERROR` included —
/// the app validates first, so the server's is a backstop). A rate limit
/// carries the server's `retryAfterSeconds` when it sent one — the bare 429
/// has none.
CommentSubmitOutcome? classifyCommentFailure(
  Failure failure, {
  required bool isReply,
}) {
  if (isCommunityRateLimited(failure)) {
    return CommentRateLimited(retryAfter: retryAfterOf(failure));
  }
  return switch (communityErrorCode(failure)) {
    CommunityErrorCodes.contentNotAllowed => const CommentFiltered(),
    CommunityErrorCodes.displayNameRequired => const CommentNameRequired(),
    CommunityErrorCodes.guidelinesNotAccepted =>
      const CommentGuidelinesRequired(),
    CommunityErrorCodes.profileNotApproved => const CommentNotApproved(),
    CommunityErrorCodes.postNotFound => const CommentPostGone(),
    CommunityErrorCodes.commentNotFound when isReply =>
      const CommentParentGone(),
    _ => null,
  };
}

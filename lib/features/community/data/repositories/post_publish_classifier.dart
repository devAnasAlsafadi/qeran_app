import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/community_post.dart';
import '../../domain/entities/post_publish_outcome.dart';
import '../error_codes.dart';
import 'community_failure_classifier.dart';

/// Her publish's answer as the composer takes it (plan §3.4): the post, an
/// outcome she has a screen for, or a failure — the failed strip (D3) for
/// everything else, offline and timeouts included.
Either<Failure, PostPublishOutcome> postPublishOutcomeOf(
  Either<Failure, CommunityPost> result,
) => result.fold(
  (failure) => switch (communityErrorCode(failure)) {
    CommunityErrorCodes.contentNotAllowed => const Right(PostRejected()),
    CommunityErrorCodes.guidelinesNotAccepted => const Right(
      PostGuidelinesRequired(),
    ),
    _ => Left(failure),
  },
  (post) => Right(PostPublished(post)),
);

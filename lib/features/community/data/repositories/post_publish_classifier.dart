import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/community_post.dart';
import '../../domain/entities/media_refusal.dart';
import '../../domain/entities/media_upload_outcome.dart';
import '../../domain/entities/post_publish_outcome.dart';
import '../error_codes.dart';
import 'community_failure_classifier.dart';

/// Her publish's answer as the composer takes it (plan §3.4's table): the
/// post, an outcome she has a screen for, or a failure. Failures get the
/// failed strip (D3): offline, timeouts, 429, `MEDIA_LIMIT_REACHED` (S7)
/// and anything unknown.
Either<Failure, PostPublishOutcome> postPublishOutcomeOf(
  Either<Failure, CommunityPost> result,
) => result.fold(
  (failure) => switch (_publishStopOf(communityErrorCode(failure))) {
    final PostPublishOutcome outcome => Right(outcome),
    null => Left(failure),
  },
  (post) => Right(PostPublished(post)),
);

/// One media upload's answer (6.7, 6.8): uploaded, refused by the server's
/// own check, the video service down, or a failure (D3; her cancel too).
Either<Failure, MediaUploadOutcome<T>> mediaUploadOutcomeOf<T>(
  Either<Failure, T> result,
) => result.fold((failure) {
  final code = communityErrorCode(failure);
  if (_refusalOf(code) case final MediaRefusal refusal) {
    return Right(MediaUploadRefused<T>(refusal));
  }
  if (code == CommunityErrorCodes.videoServiceUnavailable) {
    return Right(MediaVideoUnavailable<T>());
  }
  return Left(failure);
}, (value) => Right(MediaUploaded<T>(value)));

PostPublishOutcome? _publishStopOf(String? code) {
  if (_refusalOf(code) case final MediaRefusal refusal) {
    return PostMediaRefused(refusal);
  }
  return switch (code) {
    CommunityErrorCodes.contentNotAllowed => const PostRejected(),
    CommunityErrorCodes.guidelinesNotAccepted => const PostGuidelinesRequired(),
    CommunityErrorCodes.videoServiceUnavailable => const PostVideoUnavailable(),
    CommunityErrorCodes.validationError => const PostTextInvalid(),
    CommunityErrorCodes.mediaUploadFailed ||
    CommunityErrorCodes.mediaProcessingFailed ||
    CommunityErrorCodes.mediaNotFound ||
    CommunityErrorCodes.mediaNotReady => const PostMediaLost(),
    _ => null,
  };
}

MediaRefusal? _refusalOf(String? code) => switch (code) {
  CommunityErrorCodes.mediaTooLong => MediaRefusal.tooLong,
  CommunityErrorCodes.mediaTooLarge => MediaRefusal.tooLarge,
  CommunityErrorCodes.mediaInvalidType => MediaRefusal.invalidType,
  _ => null,
};

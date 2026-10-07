import 'package:dartz/dartz.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_flagged_item.dart';
import '../entities/community_page.dart';
import '../entities/community_post.dart';
import '../entities/media_upload_outcome.dart';
import '../entities/picked_video.dart';
import '../entities/post_publish_outcome.dart';
import '../entities/video_upload_grant.dart';

/// What the post's author does that members can't (contract §5.3, §6): her
/// own posts, deleting one, and the flags on comments under them. Its post
/// changes go out on the same stream as `CommunityRepository`'s.
abstract class CommunityAuthorRepository {
  /// 6.1 — her posts in every status, newest first.
  Future<Either<Failure, CommunityPage<CommunityPost>>> getMyPosts({
    required int page,
    required int pageSize,
  });

  /// 6.2 — announces the post she made (`CommunityPostCreated`); the
  /// filter's refusal, the guidelines' and the media codes are outcomes,
  /// not failures. [imageMediaIds] in her order, or [videoMediaId].
  Future<Either<Failure, PostPublishOutcome>> createPost({
    required String text,
    required String clientRequestId,
    List<String> imageMediaIds = const [],
    String? videoMediaId,
  });

  /// 6.3 — announces the post gone. One already gone counts as deleted.
  Future<Either<Failure, Unit>> deletePost(int postId);

  /// 6.7 — one image: its `mediaId`, or the server's refusal as an outcome.
  /// Her cancel comes back as `UploadCancelledFailure`.
  Future<Either<Failure, MediaUploadOutcome<String>>> uploadImage(
    UploadFile file, {
    UploadProgress? onProgress,
    UploadCancel? cancel,
  });

  /// 6.8 — the grant to upload [file], her video ready to go up: its
  /// `mediaId` and Bunny's tus endpoint, or the server's refusal or the
  /// video service down as an outcome. [durationSeconds] is the length her
  /// picked video was checked at (BA-A9).
  Future<Either<Failure, MediaUploadOutcome<VideoUploadGrant>>>
  requestVideoUpload(PickedVideo file, {required int durationSeconds});

  /// [file] to Bunny Stream with tus under [grant] (plan §3.4): from
  /// [resumeAt]'s offset while Bunny still has that upload; [onCreated]
  /// gets a new upload's URL. Her cancel comes back as
  /// `UploadCancelledFailure`.
  Future<Either<Failure, Unit>> uploadVideo(
    VideoUploadGrant grant,
    PickedVideo file, {
    Uri? resumeAt,
    void Function(Uri uploadUrl)? onCreated,
    UploadProgress? onProgress,
    UploadCancel? cancel,
  });

  /// 6.9 — media from an attempt she cancelled (S6). Best effort: what
  /// isn't attached to a post within 24 h is deleted anyway.
  Future<Either<Failure, Unit>> deleteMedia(String mediaId);

  /// 5.3 — open flags on her posts, newest report first.
  Future<Either<Failure, CommunityPage<CommunityFlaggedItem>>> getFlags({
    required int page,
    required int pageSize,
  });

  /// 5.3 — keep the item: its flag clears for her; admin still sees it.
  Future<Either<Failure, Unit>> dismissFlag(int flagId);
}

import 'package:equatable/equatable.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';

enum PublishStatus {
  idle,

  /// Her video being made ready on the phone (D1): the strip with its
  /// progress and «إلغاء»; the draft dimmed and locked.
  compressing,

  /// Her media going up (D2): the strip with its progress and «إلغاء»; the
  /// draft dimmed and locked.
  uploading,

  /// The post being made: «نشر» shows a loader and the draft is locked (S3).
  /// With media, the strip stays at 100 % and can't be cancelled any more.
  publishing,

  /// Made (D5); the composer closes onto «منشوراتي».
  published,

  /// Didn't get through: the failed strip with its retry (D3).
  failed,

  /// The video service is down (BA-A6): its own strip, with the retry.
  videoUnavailable,

  /// The filter refused the text (BA-A7).
  rejected,

  /// New guidelines to agree to first (§3.1).
  guidelinesRequired,

  /// The server's own check refused her media (Q3, C10): the draft says why.
  refused,

  /// The server refused the text's length (C7): the limits are read again.
  textInvalid,
}

/// Where her publish stands. [attempt] tells two answers apart.
class PostPublishState extends Equatable {
  const PostPublishState({
    this.status = PublishStatus.idle,
    this.post,
    this.attempt = 0,
    this.progress,
    this.refusal,
    this.refusedPath,
    this.refusedBytes,
  });

  final PublishStatus status;

  /// The post made, once [PublishStatus.published].
  final CommunityPost? post;
  final int attempt;

  /// From 0 to 1 while this attempt's media goes up; null for a text post,
  /// which shows no strip (S3).
  final double? progress;

  /// What was refused, once [PublishStatus.refused]; [refusedPath] is the
  /// image or the video, when it's known which. [refusedBytes] is the size
  /// of the video file that would have gone up (Q3).
  final MediaRefusal? refusal;
  final String? refusedPath;
  final int? refusedBytes;

  bool get busy => cancellable || status == PublishStatus.publishing;

  /// Her video is still being prepared or her media is still going up:
  /// «إلغاء» and × can stop it (D1, D2, D2b).
  bool get cancellable =>
      status == PublishStatus.compressing || status == PublishStatus.uploading;

  @override
  List<Object?> get props => [
    status,
    post,
    attempt,
    progress,
    refusal,
    refusedPath,
    refusedBytes,
  ];
}

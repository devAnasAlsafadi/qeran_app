import 'dart:async';

import '../entities/media_upload_outcome.dart';
import '../entities/picked_video.dart';
import '../entities/post_publish_outcome.dart';
import '../entities/publish_event.dart';
import '../entities/publish_session.dart';
import '../entities/video_upload_grant.dart';
import 'upload_attempt.dart';

/// Her ready video sent up (plan §3.4, D2): 6.8's grant, then the file with
/// tus straight to Bunny Stream, progress by Bunny's offset. The session
/// keeps the grant and tus's upload URL, so Retry goes on from Bunny's
/// offset (D3) and doesn't send a file that is all there again. A grant
/// about to run out, or one for another file, is replaced, and its media
/// deleted, best effort.
class VideoUpload extends UploadAttempt {
  VideoUpload(
    super.repository,
    super.session,
    super.cancel,
    super.emit, {
    required DateTime Function() now,
  }) : _now = now;

  /// How long a grant must still run for the rest of the file to go up
  /// under it.
  static const _margin = Duration(minutes: 10);

  final DateTime Function() _now;

  /// [file] — her [picked] video made ready — sent up: its media id, or
  /// null once the attempt ended here.
  Future<String?> upload(PickedVideo picked, PickedVideo file) async {
    final usable = _usable(file);
    progress((usable?.complete ?? false) ? 1 : 0, 1);
    final record = usable ?? await _grant(picked, file);
    if (record == null) return null;
    if (!record.complete && !await _send(record, file)) return null;
    if (!cancel.isCancelled) return record.grant.mediaId;
    cancelled();
    return null;
  }

  /// The upload begun for [file], unless it was for another file or its
  /// grant runs out within [_margin] before all of the file is there.
  VideoUploadRecord? _usable(PickedVideo file) {
    final record = session.pendingVideo;
    if (record == null) return null;
    if (record.path == file.path &&
        (record.complete || !_expiring(record.grant))) {
      return record;
    }
    unawaited(repository.deleteMedia(record.grant.mediaId));
    session.forgetVideo();
    return null;
  }

  bool _expiring(VideoUploadGrant grant) {
    final expiresAt = grant.expiresAt;
    return expiresAt != null && !expiresAt.isAfter(_now().add(_margin));
  }

  /// 6.8 for [file]. Its length is the one [picked] was checked at (BA-A9),
  /// so the server's check agrees with ours.
  Future<VideoUploadRecord?> _grant(
    PickedVideo picked,
    PickedVideo file,
  ) async {
    final result = await repository.requestVideoUpload(
      file,
      durationSeconds: picked.durationSeconds,
    );
    return result.fold(stopped, (outcome) {
      switch (outcome) {
        case MediaUploaded(:final value):
          return session.rememberGrant(file.path, value);
        case MediaUploadRefused(:final refusal):
          emit(
            PublishVideoRefused(
              path: picked.path,
              refusal: refusal,
              sizeBytes: file.info.sizeBytes,
            ),
          );
        case MediaVideoUnavailable():
          emit(const PublishAnswered(PostVideoUnavailable()));
      }
      return null;
    });
  }

  /// The rest of [file] to Bunny, from where Bunny has it.
  Future<bool> _send(VideoUploadRecord record, PickedVideo file) async {
    final result = await repository.uploadVideo(
      record.grant,
      file,
      resumeAt: record.uploadUrl,
      onCreated: (url) => record.uploadUrl = url,
      onProgress: progress,
      cancel: cancel,
    );
    return result.fold(
      (failure) => stopped<bool>(failure) ?? false,
      (_) => record.complete = true,
    );
  }
}

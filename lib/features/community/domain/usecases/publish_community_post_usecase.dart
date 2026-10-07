import 'dart:async';

import 'package:qeran/core/domain/upload.dart';

import '../entities/picked_video.dart';
import '../entities/post_draft.dart';
import '../entities/post_publish_outcome.dart';
import '../entities/publish_event.dart';
import '../entities/publish_session.dart';
import '../ports/video_compressor.dart';
import '../repositories/community_author_repository.dart';
import 'image_uploads.dart';
import 'video_preparation.dart';
import 'video_upload.dart';

/// Publishing her post (plan §3.4): her images go up one after another in
/// her order (S5), or her video is made ready (D1) and sent to Bunny with
/// tus (D2), then 6.2 makes the post with their ids. [PublishSession]
/// carries what earlier attempts did, so Retry doesn't send an image twice,
/// compress a video again or start its upload over, and keeps the request
/// id while the draft is unchanged. A cancel deletes this session's
/// uploads, best effort (S6).
class PublishCommunityPostUseCase {
  final CommunityAuthorRepository _repository;
  final VideoCompressor _compressor;

  /// The clock a video's grant is read against (its `expiresAt`).
  final DateTime Function() _now;

  const PublishCommunityPostUseCase(
    this._repository,
    this._compressor, {
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  /// One attempt at [draft]: progress, then exactly one ending.
  Stream<PublishEvent> call(PostDraft draft, PublishSession session) {
    final events = StreamController<PublishEvent>();
    _run(draft, session, events.add).whenComplete(events.close);
    return events.stream;
  }

  /// Her composer closed: the compressed copies it made go (plan §3.4).
  Future<void> deleteCopies() => _compressor.deleteCopies();

  Future<void> _run(
    PostDraft draft,
    PublishSession session,
    PublishEmit emit,
  ) async {
    final cancel = session.begin();
    if (draft.video case final video?) {
      final id = await _video(video, draft, session, cancel, emit);
      if (id != null) await _create(draft, session, emit, videoId: id);
      return;
    }
    final ids = await ImageUploads(
      _repository,
      session,
      cancel,
      emit,
    ).upload(draft.images);
    if (ids != null) await _create(draft, session, emit, imageIds: ids);
  }

  /// Her video made ready, then sent up: its media id, or null once the
  /// attempt ended there.
  Future<String?> _video(
    PickedVideo video,
    PostDraft draft,
    PublishSession session,
    UploadCancel cancel,
    PublishEmit emit,
  ) async {
    final file = await VideoPreparation(
      _compressor,
      session,
      cancel,
      emit,
    ).prepare(video, maxBytes: draft.maxVideoBytes);
    if (file == null) return null;
    return VideoUpload(
      _repository,
      session,
      cancel,
      emit,
      now: _now,
    ).upload(video, file);
  }

  Future<void> _create(
    PostDraft draft,
    PublishSession session,
    PublishEmit emit, {
    List<String> imageIds = const [],
    String? videoId,
  }) async {
    if (imageIds.isNotEmpty || videoId != null) emit(const PublishCreating());
    final result = await _repository.createPost(
      text: draft.text,
      clientRequestId: session.requestIdFor(draft),
      imageMediaIds: imageIds,
      videoMediaId: videoId,
    );
    result.fold((failure) => emit(PublishFailed(failure)), (outcome) {
      // Used by the post, or lost: either way not to be sent again as is.
      if (outcome is PostPublished || outcome is PostMediaLost) {
        session.forgetUploads();
      }
      emit(PublishAnswered(outcome));
    });
  }
}

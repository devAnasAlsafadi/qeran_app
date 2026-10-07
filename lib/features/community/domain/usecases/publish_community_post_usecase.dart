import 'dart:async';

import '../entities/post_draft.dart';
import '../entities/post_publish_outcome.dart';
import '../entities/publish_event.dart';
import '../entities/publish_session.dart';
import '../ports/video_compressor.dart';
import '../repositories/community_author_repository.dart';
import 'image_uploads.dart';
import 'video_preparation.dart';

/// Publishing her post (plan §3.4): her images go up one after another in
/// her order (S5), or her video is made ready (D1), then 6.2 makes the post
/// with their ids. [PublishSession] carries what earlier attempts did, so
/// Retry doesn't send an image twice or compress a video again, and keeps
/// the request id while the draft is unchanged. A cancel deletes this
/// session's uploads, best effort (S6).
class PublishCommunityPostUseCase {
  final CommunityAuthorRepository _repository;
  final VideoCompressor _compressor;
  const PublishCommunityPostUseCase(this._repository, this._compressor);

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
      final file = await VideoPreparation(
        _compressor,
        session,
        cancel,
        emit,
      ).prepare(video, maxBytes: draft.maxVideoBytes);
      if (file == null) return;
      // Sub-step 13 uploads it (6.8, tus). Until then the composer can't
      // send a video (sub-step 11), and an attempt that could ends as
      // BA-A6 does.
      return emit(const PublishAnswered(PostVideoUnavailable()));
    }
    final ids = await ImageUploads(
      _repository,
      session,
      cancel,
      emit,
    ).upload(draft.images);
    if (ids == null) return;
    await _create(draft, session, ids, emit);
  }

  Future<void> _create(
    PostDraft draft,
    PublishSession session,
    List<String> ids,
    PublishEmit emit,
  ) async {
    if (draft.images.isNotEmpty) emit(const PublishCreating());
    final result = await _repository.createPost(
      text: draft.text,
      clientRequestId: session.requestIdFor(draft),
      imageMediaIds: ids,
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

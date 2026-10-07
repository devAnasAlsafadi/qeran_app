import 'dart:async';

import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/media_upload_outcome.dart';
import '../entities/picked_image.dart';
import '../entities/post_draft.dart';
import '../entities/post_publish_outcome.dart';
import '../entities/publish_event.dart';
import '../entities/publish_session.dart';
import '../ports/video_compressor.dart';
import '../repositories/community_author_repository.dart';
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
    final ids = await _ImageUploads(
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

/// One attempt's images: each sent once, progress by bytes across all of
/// them, reported per whole percent.
class _ImageUploads {
  _ImageUploads(this._repository, this._session, this._cancel, this._emit);

  final CommunityAuthorRepository _repository;
  final PublishSession _session;
  final UploadCancel _cancel;
  final PublishEmit _emit;
  int _total = 0;
  int _percent = -1;

  /// Their ids in her order, or null once the attempt ended here.
  Future<List<String>?> upload(List<PickedImage> images) async {
    if (images.isEmpty) return const [];
    _total = images.fold(0, (sum, image) => sum + image.sizeBytes);
    var done = 0;
    final ids = <String>[];
    _progress(0);
    for (final image in images) {
      final id = _session.uploadedId(image.path) ?? await _send(image, done);
      if (id == null) return null;
      done += image.sizeBytes;
      ids.add(id);
      _progress(done);
    }
    if (!_cancel.isCancelled) return ids;
    _cancelled();
    return null;
  }

  Future<String?> _send(PickedImage image, int done) async {
    final result = await _repository.uploadImage(
      image.file,
      cancel: _cancel,
      onProgress: (sent, total) =>
          _progress(done + (total == 0 ? 0 : image.sizeBytes * sent ~/ total)),
    );
    return result.fold(_stopped, (outcome) {
      switch (outcome) {
        case MediaUploaded(:final value):
          _session.remember(image.path, value);
          return value;
        case MediaUploadRefused(:final refusal):
          _emit(PublishImageRefused(path: image.path, refusal: refusal));
        case MediaVideoUnavailable():
          _emit(const PublishAnswered(PostVideoUnavailable()));
      }
      return null;
    });
  }

  String? _stopped(Failure failure) {
    failure is UploadCancelledFailure
        ? _cancelled()
        : _emit(PublishFailed(failure));
    return null;
  }

  /// Her cancel: what went up is deleted, best effort, and sent again from
  /// the start next time.
  void _cancelled() {
    for (final id in _session.uploadedIds) {
      unawaited(_repository.deleteMedia(id));
    }
    _session.forgetUploads();
    _emit(const PublishCancelled());
  }

  void _progress(int sentBytes) {
    final percent = _total == 0 ? 100 : sentBytes * 100 ~/ _total;
    if (percent == _percent) return;
    _percent = percent;
    _emit(PublishUploading(percent / 100));
  }
}

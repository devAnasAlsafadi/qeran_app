import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/post_draft.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/entities/publish_event.dart';
import 'package:qeran/features/community/domain/entities/publish_session.dart';
import 'package:qeran/features/community/domain/usecases/publish_community_post_usecase.dart';
import 'package:uuid/uuid.dart';

import 'post_publish_state.dart';

export 'post_publish_state.dart';

/// Publishing her draft (6.7, 6.2). One [PublishSession] for the composer's
/// life: a retry keeps the request id while the draft is unchanged (W16)
/// and doesn't send an image twice.
class PostPublishCubit extends Cubit<PostPublishState>
    with SafeEmit<PostPublishState> {
  PostPublishCubit({
    required PublishCommunityPostUseCase publish,
    String Function()? newRequestId,
  }) : _publish = publish,
       _session = PublishSession(newRequestId: newRequestId ?? const Uuid().v4),
       super(const PostPublishState());

  final PublishCommunityPostUseCase _publish;
  final PublishSession _session;

  /// Sends [draft] (its text trimmed here). Ignored while one is on its way.
  Future<void> publish(PostDraft draft) async {
    if (state.busy) return;
    final attempt = state.attempt + 1;
    final first = _firstStatus(draft);
    emit(
      PostPublishState(
        status: first,
        attempt: attempt,
        progress: first == PublishStatus.publishing ? null : 0,
      ),
    );
    final trimmed = PostDraft(
      text: draft.text.trim(),
      images: draft.images,
      video: draft.video,
      maxVideoBytes: draft.maxVideoBytes,
    );
    await for (final event in _publish(trimmed, _session)) {
      emit(_stateOf(event, attempt));
    }
  }

  /// A video not yet made ready starts there (D1); media starts going up
  /// (D2); a text post is made at once (S3).
  PublishStatus _firstStatus(PostDraft draft) => switch (draft) {
    PostDraft(:final video?) when _session.preparedVideo(video.path) == null =>
      PublishStatus.compressing,
    PostDraft(video: _?) ||
    PostDraft(images: [_, ...]) => PublishStatus.uploading,
    _ => PublishStatus.publishing,
  };

  /// Stops her video being prepared or her media going up (D1, D2): the
  /// draft is hers again. Once the post is being made it's too late, and
  /// nothing happens.
  void cancel() {
    if (state.cancellable) _session.cancel();
  }

  PostPublishState _stateOf(PublishEvent event, int attempt) {
    PostPublishState at(PublishStatus status, {double? progress}) =>
        PostPublishState(status: status, attempt: attempt, progress: progress);
    return switch (event) {
      PublishCompressing(:final progress) => at(
        PublishStatus.compressing,
        progress: progress,
      ),
      PublishUploading(:final progress) => at(
        PublishStatus.uploading,
        progress: progress,
      ),
      PublishCreating() => at(PublishStatus.publishing, progress: 1),
      PublishAnswered(:final outcome) => _answered(outcome, attempt),
      PublishImageRefused(:final path, :final refusal) => _refused(
        attempt,
        refusal,
        path: path,
      ),
      PublishVideoRefused(:final path, :final refusal, :final sizeBytes) =>
        _refused(attempt, refusal, path: path, bytes: sizeBytes),
      PublishFailed() => at(PublishStatus.failed),
      PublishCancelled() => at(PublishStatus.idle),
    };
  }

  /// The composer closed: what's on its way stops, and the compressed
  /// copies go.
  @override
  Future<void> close() {
    _session.cancel();
    unawaited(_publish.deleteCopies());
    return super.close();
  }

  static PostPublishState _answered(PostPublishOutcome outcome, int attempt) {
    PostPublishState at(PublishStatus status) =>
        PostPublishState(status: status, attempt: attempt);
    return switch (outcome) {
      PostPublished(:final post) => PostPublishState(
        status: PublishStatus.published,
        post: post,
        attempt: attempt,
      ),
      PostRejected() => at(PublishStatus.rejected),
      PostGuidelinesRequired() => at(PublishStatus.guidelinesRequired),
      PostMediaRefused(:final refusal) => _refused(attempt, refusal),
      PostTextInvalid() => at(PublishStatus.textInvalid),
      // Lost media is sent again on Retry.
      PostMediaLost() => at(PublishStatus.failed),
      PostVideoUnavailable() => at(PublishStatus.videoUnavailable),
    };
  }

  static PostPublishState _refused(
    int attempt,
    MediaRefusal refusal, {
    String? path,
    int? bytes,
  }) => PostPublishState(
    status: PublishStatus.refused,
    attempt: attempt,
    refusal: refusal,
    refusedPath: path,
    refusedBytes: bytes,
  );
}

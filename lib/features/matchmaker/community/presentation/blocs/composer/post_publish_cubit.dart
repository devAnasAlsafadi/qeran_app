import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/create_community_post_usecase.dart';
import 'package:uuid/uuid.dart';

enum PublishStatus {
  idle,

  /// On its way: «نشر» shows a loader and the draft is locked (S3).
  publishing,

  /// Made (D5); the composer closes onto «منشوراتي».
  published,

  /// Didn't get through: the failed strip with its retry (D3).
  failed,

  /// The filter refused the text (BA-A7).
  rejected,

  /// New guidelines to agree to first (§3.1).
  guidelinesRequired,
}

/// Where her publish stands. [attempt] tells two answers apart.
class PostPublishState extends Equatable {
  const PostPublishState({
    this.status = PublishStatus.idle,
    this.post,
    this.attempt = 0,
  });

  final PublishStatus status;

  /// The post made, once [PublishStatus.published].
  final CommunityPost? post;
  final int attempt;

  bool get busy => status == PublishStatus.publishing;

  @override
  List<Object?> get props => [status, post, attempt];
}

/// Publishing her draft (6.2). Each attempt carries a `clientRequestId`:
/// the same one while the text is what went out last — so a retry after a
/// lost answer returns the post that was made, never a second (W16) — and
/// a new one once she changes it.
class PostPublishCubit extends Cubit<PostPublishState>
    with SafeEmit<PostPublishState> {
  PostPublishCubit({
    required CreateCommunityPostUseCase createPost,
    String Function()? newRequestId,
  }) : _createPost = createPost,
       _newRequestId = newRequestId ?? const Uuid().v4,
       super(const PostPublishState());

  final CreateCommunityPostUseCase _createPost;
  final String Function() _newRequestId;
  String? _requestId;
  String? _requestText;

  Future<void> publish(String text) async {
    if (state.busy) return;
    final trimmed = text.trim();
    final requestId = _requestIdFor(trimmed);
    final attempt = state.attempt + 1;
    emit(PostPublishState(status: PublishStatus.publishing, attempt: attempt));
    final result = await _createPost(text: trimmed, clientRequestId: requestId);
    emit(
      result.fold(
        (_) => PostPublishState(status: PublishStatus.failed, attempt: attempt),
        (outcome) => _stateOf(outcome, attempt),
      ),
    );
  }

  String _requestIdFor(String text) {
    if (text != _requestText || _requestId == null) {
      _requestText = text;
      _requestId = _newRequestId();
    }
    return _requestId!;
  }

  static PostPublishState _stateOf(PostPublishOutcome outcome, int attempt) =>
      switch (outcome) {
        PostPublished(:final post) => PostPublishState(
          status: PublishStatus.published,
          post: post,
          attempt: attempt,
        ),
        PostRejected() => PostPublishState(
          status: PublishStatus.rejected,
          attempt: attempt,
        ),
        PostGuidelinesRequired() => PostPublishState(
          status: PublishStatus.guidelinesRequired,
          attempt: attempt,
        ),
        // A text post's server backstop, and media outcomes a text post
        // can't get: the failed strip, as before (their own states come
        // with the media sub-steps).
        PostTextInvalid() ||
        PostVideoUnavailable() ||
        PostMediaRefused() ||
        PostMediaLost() => PostPublishState(
          status: PublishStatus.failed,
          attempt: attempt,
        ),
      };
}

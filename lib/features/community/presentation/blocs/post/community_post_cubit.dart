import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/errors.dart';
import '../../../../../core/state/safe_emit.dart';
import '../../../data/error_codes.dart';
import '../../../domain/entities/community_like_state.dart';
import '../../../domain/entities/community_media.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/community_post_change.dart';
import '../../../domain/usecases/get_community_post_usecase.dart';
import '../../../domain/usecases/set_post_like_usecase.dart';
import '../../../domain/usecases/watch_community_post_changes_usecase.dart';
import '../../video/post_video.dart';
import '../likes.dart';
import 'community_post_state.dart';

/// The post at the top of its screen (C1, C7): shown at once from the feed's
/// copy while a fresh one is read, its optimistic like, and gone the moment
/// the server says so — from its own read, a like, or the comments' read,
/// which the repository announces on its stream.
class CommunityPostCubit extends Cubit<CommunityPostState>
    with SafeEmit<CommunityPostState> {
  CommunityPostCubit({
    required int postId,
    CommunityPost? post,
    required GetCommunityPostUseCase getPost,
    required SetPostLikeUseCase setPostLike,
    required WatchCommunityPostChangesUseCase watchChanges,
  }) : _postId = postId,
       _getPost = getPost,
       _setPostLike = setPostLike,
       super(
         post == null ? const CommunityPostLoading() : CommunityPostReady(post),
       ) {
    _changes = watchChanges().listen(_onChange);
  }

  final int _postId;
  final GetCommunityPostUseCase _getPost;
  final SetPostLikeUseCase _setPostLike;
  late final StreamSubscription<CommunityPostChange> _changes;
  bool _loading = false;

  /// The like on its way: a second tap waits for the answer.
  bool _liking = false;

  /// Reads the post. A copy already on screen stays while the fresh one
  /// comes, and stays if it can't be read; without one, the error state.
  Future<void> load() async {
    if (_loading || state is CommunityPostRemoved) return;
    _loading = true;
    final shown = state is CommunityPostReady;
    if (!shown) emit(const CommunityPostLoading());
    final result = await _getPost(_postId);
    _loading = false;
    result.fold((failure) {
      if (_isGone(failure)) return emit(const CommunityPostRemoved());
      if (!shown) emit(const CommunityPostFailed());
    }, _show);
  }

  /// The post's video read again, for a lapsed link (S19). A copy that
  /// couldn't be read leaves the old one, and its player says so.
  Future<CommunityVideo?> freshVideo() async {
    await load();
    final s = state;
    return s is CommunityPostReady ? videoOf(s.post) : null;
  }

  /// Like or unlike the post at once, then settle on the server's answer;
  /// on failure, take it back and say so. A [readOnly] member is told why
  /// instead — and so is one the server turns away.
  Future<void> toggleLike({bool readOnly = false}) async {
    final s = state;
    if (s is! CommunityPostReady) return;
    if (readOnly) return emit(s.withEvent(CommunityPostEvent.readOnlyLike));
    if (_liking) return;
    _liking = true;
    final before = s.post.like;
    emit(s.withPost(s.post.withLike(before.flipped)));
    final result = await _setPostLike(_postId, liked: !before.likedByMe);
    _liking = false;
    result.fold((failure) => _takeBack(before, failure), _applyLike);
  }

  void _show(CommunityPost post) {
    final s = state;
    if (s is CommunityPostRemoved) return;
    emit(s is CommunityPostReady ? s.withPost(post) : CommunityPostReady(post));
  }

  void _applyLike(CommunityLikeState like) {
    final s = state;
    if (s is CommunityPostReady) emit(s.withPost(s.post.withLike(like)));
  }

  void _takeBack(CommunityLikeState before, Failure failure) {
    final s = state;
    // A post gone meanwhile has nothing to take back.
    if (s is! CommunityPostReady) return;
    final event = isNotApprovedFailure(failure)
        ? CommunityPostEvent.readOnlyLike
        : CommunityPostEvent.likeFailed;
    emit(s.withPost(s.post.withLike(before)).withEvent(event));
  }

  static bool _isGone(Failure failure) =>
      failure is CodedServerFailure &&
      failure.errorCode == CommunityErrorCodes.postNotFound;

  void _onChange(CommunityPostChange change) {
    if (change.postId != _postId) return;
    switch (change) {
      case CommunityPostGone():
        emit(const CommunityPostRemoved());
      case CommunityPostUpdated(:final post):
        _show(post);
      case CommunityPostLikeChanged(:final like):
        if (!_liking) _applyLike(like);
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

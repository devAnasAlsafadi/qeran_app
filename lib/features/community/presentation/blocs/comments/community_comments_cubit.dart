import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/state/safe_emit.dart';
import '../../../domain/entities/community_like_state.dart';
import '../../../domain/usecases/get_comment_replies_usecase.dart';
import '../../../domain/usecases/get_post_comments_usecase.dart';
import '../../../domain/usecases/set_comment_like_usecase.dart';
import '../likes.dart';
import 'comment_thread.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

/// A post's discussion (C1–C6): comments newest first, a page at a time
/// on «عرض تعليقات أخرى», each comment's replies oldest first on «عرض
/// الردود», and the optimistic like on a comment or a reply.
class CommunityCommentsCubit extends Cubit<CommunityCommentsState>
    with SafeEmit<CommunityCommentsState> {
  CommunityCommentsCubit({
    required int postId,
    required GetPostCommentsUseCase getComments,
    required GetCommentRepliesUseCase getReplies,
    required SetCommentLikeUseCase setCommentLike,
  }) : _postId = postId,
       _getComments = getComments,
       _getReplies = getReplies,
       _setCommentLike = setCommentLike,
       super(const CommunityCommentsState());

  final int _postId;
  final GetPostCommentsUseCase _getComments;
  final GetCommentRepliesUseCase _getReplies;
  final SetCommentLikeUseCase _setCommentLike;
  bool _loading = false;

  /// Comments and replies whose like is on its way: a second tap waits.
  final Set<int> _liking = {};

  /// The first page — on opening, and from the error's retry (C6).
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    emit(state.copyWith(status: CommunityCommentsStatus.loading));
    final result = await _getComments(_postId, page: 1);
    _loading = false;
    result.fold(
      (_) => emit(state.copyWith(status: CommunityCommentsStatus.failure)),
      (page) {
        final threads = appendNewThreads(const [], page.items);
        emit(
          state.copyWith(
            status: threads.isEmpty
                ? CommunityCommentsStatus.empty
                : CommunityCommentsStatus.loaded,
            threads: threads,
            page: page.pageNumber,
            hasMore: page.hasMore,
            pageFailed: false,
          ),
        );
      },
    );
  }

  /// The next page, on «عرض تعليقات أخرى» or its retry (C3).
  Future<void> loadMore() async {
    final s = state;
    final ready = s.status == CommunityCommentsStatus.loaded && s.hasMore;
    if (!ready || s.loadingMore) return;
    emit(s.copyWith(loadingMore: true, pageFailed: false));
    final result = await _getComments(_postId, page: s.page + 1);
    result.fold(
      (_) => emit(state.copyWith(loadingMore: false, pageFailed: true)),
      (page) => emit(
        state.copyWith(
          threads: appendNewThreads(state.threads, page.items),
          page: page.pageNumber,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  /// [commentId]'s first page of replies, or its next (C2) — the link's
  /// tap, and its retry.
  Future<void> showReplies(int commentId) async {
    final thread = _thread(commentId);
    if (thread == null || thread.repliesStatus == RepliesStatus.loading) {
      return;
    }
    _setThread(
      commentId,
      (t) => t.copyWith(repliesStatus: RepliesStatus.loading),
    );
    final result = await _getReplies(commentId, page: thread.repliesPage + 1);
    result.fold(
      (_) => _setThread(
        commentId,
        (t) => t.copyWith(repliesStatus: RepliesStatus.failed),
      ),
      (page) => _setThread(commentId, (t) => withRepliesPage(t, page)),
    );
  }

  /// Like or unlike a comment or a reply at once, then settle on the
  /// server's answer; on failure, take it back and say so. A [readOnly]
  /// member is told why instead — and so is one the server turns away.
  Future<void> toggleLike(int commentId, {bool readOnly = false}) async {
    if (readOnly) {
      return emit(state.withEvent(CommunityCommentsEvent.readOnlyLike));
    }
    final before = findComment(state.threads, commentId)?.like;
    if (before == null || !_liking.add(commentId)) return;
    _setLike(commentId, before.flipped);
    final result = await _setCommentLike(commentId, liked: !before.likedByMe);
    _liking.remove(commentId);
    result.fold((failure) {
      _setLike(commentId, before);
      emit(
        state.withEvent(
          isNotApprovedFailure(failure)
              ? CommunityCommentsEvent.readOnlyLike
              : CommunityCommentsEvent.likeFailed,
        ),
      );
    }, (like) => _setLike(commentId, like));
  }

  CommentThread? _thread(int commentId) =>
      state.threads.where((t) => t.id == commentId).firstOrNull;

  void _setThread(
    int commentId,
    CommentThread Function(CommentThread thread) update,
  ) => emit(
    state.copyWith(threads: updateThread(state.threads, commentId, update)),
  );

  void _setLike(int commentId, CommunityLikeState like) => emit(
    state.copyWith(threads: withCommentLike(state.threads, commentId, like)),
  );
}

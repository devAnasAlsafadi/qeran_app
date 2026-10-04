import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/state/safe_emit.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_page.dart';
import '../../../domain/usecases/create_community_comment_usecase.dart';
import '../../../domain/usecases/create_community_reply_usecase.dart';
import '../../../domain/usecases/delete_community_comment_usecase.dart';
import '../../../domain/usecases/get_comment_replies_usecase.dart';
import '../../../domain/usecases/get_community_post_usecase.dart';
import '../../../domain/usecases/get_post_comments_usecase.dart';
import '../../../domain/usecases/set_comment_like_usecase.dart';
import 'comment_likes.dart';
import 'comment_removal.dart';
import 'comment_sending.dart';
import 'comment_thread.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

/// A post's discussion (C1–C6, D5–D10): comments newest first, a page at a
/// time on «عرض تعليقات أخرى», each comment's replies oldest first on «عرض
/// الردود», the optimistic like ([CommentLikes]), what the member sends
/// ([CommentSending]) and what leaves the list ([CommentRemoval]).
class CommunityCommentsCubit extends Cubit<CommunityCommentsState>
    with
        SafeEmit<CommunityCommentsState>,
        CommentLikes,
        CommentSending,
        CommentRemoval {
  CommunityCommentsCubit({
    required this.postId,
    required GetPostCommentsUseCase getComments,
    required GetCommentRepliesUseCase getReplies,
    required this.setCommentLike,
    required this.createComment,
    required this.createReply,
    required this.deleteComment,
    required this.getPost,
  }) : _getComments = getComments,
       _getReplies = getReplies,
       super(const CommunityCommentsState());

  @override
  final int postId;
  @override
  final SetCommentLikeUseCase setCommentLike;
  @override
  final CreateCommunityCommentUseCase createComment;
  @override
  final CreateCommunityReplyUseCase createReply;
  @override
  final DeleteCommunityCommentUseCase deleteComment;
  @override
  final GetCommunityPostUseCase getPost;
  final GetPostCommentsUseCase _getComments;
  final GetCommentRepliesUseCase _getReplies;
  bool _loading = false;

  /// The first page — on opening, and from the error's retry (C6).
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    emit(state.copyWith(status: CommunityCommentsStatus.loading));
    final result = await _getComments(postId, page: 1);
    _loading = false;
    result.fold(
      (_) => emit(state.copyWith(status: CommunityCommentsStatus.failure)),
      (page) => emit(_firstPage(page)),
    );
  }

  /// Pull to refresh, as the feed's: the first page again, with the
  /// comments on screen until it lands — and still there if it fails.
  Future<void> refresh() async {
    final s = state;
    final settled =
        s.status == CommunityCommentsStatus.loaded ||
        s.status == CommunityCommentsStatus.empty;
    if (!settled) return load();
    if (s.refreshing) return;
    emit(s.copyWith(refreshing: true));
    final result = await _getComments(postId, page: 1);
    result.fold(
      (_) => emit(state.copyWith(refreshing: false)),
      (page) => emit(_firstPage(page)),
    );
  }

  /// The first page, keeping what the member sent that isn't settled.
  CommunityCommentsState _firstPage(CommunityPage<CommunityComment> page) {
    final threads = keepUnsettled(
      appendNewThreads(const [], page.items),
      state.threads,
      state.delivery.containsKey,
    );
    return state.copyWith(
      status: threads.isEmpty
          ? CommunityCommentsStatus.empty
          : CommunityCommentsStatus.loaded,
      threads: threads,
      page: page.pageNumber,
      hasMore: page.hasMore,
      loadingMore: false,
      pageFailed: false,
      refreshing: false,
    );
  }

  /// The next page, on «عرض تعليقات أخرى» or its retry (C3).
  Future<void> loadMore() async {
    final s = state;
    final ready = s.status == CommunityCommentsStatus.loaded && s.hasMore;
    if (!ready || s.loadingMore || s.refreshing) return;
    emit(s.copyWith(loadingMore: true, pageFailed: false));
    final result = await _getComments(postId, page: s.page + 1);
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

  CommentThread? _thread(int commentId) =>
      state.threads.where((t) => t.id == commentId).firstOrNull;

  void _setThread(
    int commentId,
    CommentThread Function(CommentThread thread) update,
  ) => emit(
    state.copyWith(threads: updateThread(state.threads, commentId, update)),
  );
}

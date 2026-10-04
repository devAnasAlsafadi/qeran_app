import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/community_comment.dart';
import '../../../domain/usecases/delete_community_comment_usecase.dart';
import '../../../domain/usecases/get_community_post_usecase.dart';
import 'comment_removals.dart';
import 'comment_thread.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

/// The comments cubit's removals: the member deleting their own comment or
/// reply (E8–E10), a reported one found gone (E7), and a blocked member's
/// rows going (E12).
mixin CommentRemoval on Cubit<CommunityCommentsState> {
  @protected
  int get postId;
  @protected
  DeleteCommunityCommentUseCase get deleteComment;
  @protected
  GetCommunityPostUseCase get getPost;

  /// Deletes on their way: a second tap waits.
  final Set<int> _deleting = {};

  /// Deletes [comment] — a comment with its replies (D16), or a reply. Once
  /// the server agrees, it leaves the list, the screen says so, and the
  /// post's counts are read again (S4); a failure keeps it, and says that.
  Future<void> delete(CommunityComment comment) async {
    if (!_deleting.add(comment.id)) return;
    final result = await deleteComment(comment.id);
    _deleting.remove(comment.id);
    result.fold(
      (_) => emit(
        state.withEvent(
          comment.isReply
              ? CommunityCommentsEvent.deleteReplyFailed
              : CommunityCommentsEvent.deleteFailed,
        ),
      ),
      (_) => comment.isReply
          ? _remove(
              withoutReply(state.threads, comment),
              CommunityCommentsEvent.deletedReply,
            )
          : _remove(
              withoutComment(state.threads, comment.id),
              CommunityCommentsEvent.deleted,
            ),
    );
  }

  /// [comment] already gone from the server — a report found it so (E7): it
  /// leaves the list as a deleted one does, with no word of its own (the
  /// report said it), and the post's counts are read again.
  void removeGone(CommunityComment comment) => _remove(
    comment.isReply
        ? withoutReply(state.threads, comment)
        : withoutComment(state.threads, comment.id),
  );

  /// [authorId]'s comments and replies gone, after the member blocked them
  /// (E12). The screen stays.
  void removeAuthor(String authorId) =>
      _remove(withoutAuthor(state.threads, authorId));

  void _remove(List<CommentThread> threads, [CommunityCommentsEvent? event]) {
    final emptied =
        threads.isEmpty && state.status == CommunityCommentsStatus.loaded;
    final next = state.copyWith(
      status: emptied ? CommunityCommentsStatus.empty : null,
      threads: threads,
    );
    emit(event == null ? next : next.withEvent(event));
    unawaited(getPost(postId));
  }
}

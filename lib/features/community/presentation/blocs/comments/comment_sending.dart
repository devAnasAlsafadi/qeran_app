import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/server_clock.dart';
import '../../../domain/entities/comment_submit_outcome.dart';
import '../../../domain/entities/community_author.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/usecases/create_community_comment_usecase.dart';
import '../../../domain/usecases/create_community_reply_usecase.dart';
import '../../../domain/usecases/get_community_post_usecase.dart';
import 'comment_thread.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

/// The comments cubit's sending: the member's comment or reply on screen at
/// once, then settled by the server's answer (D5–D10).
mixin CommentSending on Cubit<CommunityCommentsState> {
  @protected
  int get postId;
  @protected
  CreateCommunityCommentUseCase get createComment;
  @protected
  CreateCommunityReplyUseCase get createReply;
  @protected
  GetCommunityPostUseCase get getPost;

  /// Ids for what the member sends until the server gives it its own —
  /// below zero, so they never meet the server's.
  int _nextLocalId = -1;

  /// Sends [text] as [me]: a comment, or with [parentId] a reply under it.
  /// Its row shows at once, «جارٍ النشر…»; posted, it takes the server's
  /// copy and the post's counts are read again (S4); a failed send stays
  /// as a row with its retry. Anything else — the filter, the rate limit, a
  /// gate, the comment or the post gone — takes the row away and comes
  /// back, so the composer can give the text back.
  Future<CommentSubmitOutcome?> send(
    String text, {
    int? parentId,
    required CommunityAuthor me,
  }) {
    final local = _local(text, parentId, me);
    final threads = parentId == null
        ? withMyComment(state.threads, local)
        : withMyReply(state.threads, local);
    final wasEmpty = state.status == CommunityCommentsStatus.empty;
    emit(
      state.copyWith(
        status: wasEmpty ? CommunityCommentsStatus.loaded : null,
        threads: threads,
        delivery: {...state.delivery, local.id: CommentDelivery.pending},
      ),
    );
    return _deliver(local);
  }

  /// [text] as the member's own, until the server's copy replaces it.
  CommunityComment _local(String text, int? parentId, CommunityAuthor me) =>
      CommunityComment(
        id: _nextLocalId--,
        postId: postId,
        parentCommentId: parentId,
        author: me,
        text: text,
        likeCount: 0,
        likedByMe: false,
        replyCount: 0,
        createdAt: ServerClock.instance.now(),
        isMine: true,
        canDelete: false,
        canBlock: false,
      );

  /// The failed [localId] sent again, the same text (D7).
  Future<CommentSubmitOutcome?> retry(int localId) async {
    final local = findComment(state.threads, localId);
    if (local == null || state.delivery[localId] != CommentDelivery.failed) {
      return null;
    }
    _mark(localId, CommentDelivery.pending);
    return _deliver(local);
  }

  Future<CommentSubmitOutcome?> _deliver(CommunityComment local) async {
    final parent = local.parentCommentId;
    final result = parent == null
        ? await createComment(postId, local.text)
        : await createReply(parent, local.text);
    return result.fold((_) {
      _mark(local.id, CommentDelivery.failed);
      return null;
    }, (outcome) => _settle(local, outcome));
  }

  CommentSubmitOutcome? _settle(
    CommunityComment local,
    CommentSubmitOutcome outcome,
  ) {
    final delivery = {...state.delivery}..remove(local.id);
    if (outcome is CommentPosted) {
      final threads = withPosted(state.threads, local.id, outcome.comment);
      emit(state.copyWith(threads: threads, delivery: delivery));
      unawaited(getPost(postId));
      return null;
    }
    var threads = withoutComment(state.threads, local.id);
    // S9: the comment it answered is gone, so its thread goes too.
    if (outcome is CommentParentGone) {
      threads = withoutComment(threads, local.parentCommentId!);
    }
    final emptied =
        threads.isEmpty && state.status == CommunityCommentsStatus.loaded;
    emit(
      state.copyWith(
        status: emptied ? CommunityCommentsStatus.empty : null,
        threads: threads,
        delivery: delivery,
      ),
    );
    // A read of the post tells the screen it's gone.
    if (outcome is CommentPostGone) unawaited(getPost(postId));
    return outcome;
  }

  void _mark(int id, CommentDelivery delivery) =>
      emit(state.copyWith(delivery: {...state.delivery, id: delivery}));
}

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/errors.dart';
import '../../../data/error_codes.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_landing.dart';
import '../../../domain/entities/community_page.dart';
import '../../../domain/usecases/get_community_comment_usecase.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

typedef CommentsPage = Either<Failure, CommunityPage<CommunityComment>>;

/// The comments cubit's landing (C8, S7): opened from a notification, the
/// discussion starts with the comment it's about — first, whatever its age
/// (K11) — and the reply it's about under it, highlighted.
mixin CommentLanding on Cubit<CommunityCommentsState> {
  @protected
  GetCommunityCommentUseCase get getComment;

  /// The discussion from [page] as it is, without a landing.
  @protected
  CommunityCommentsState firstPageState(CommunityPage<CommunityComment> page);

  /// Where to land, until it has: the error's retry lands again.
  @protected
  CommunityLanding? pendingLanding;

  /// [target]'s comment and reply, read beside the first page; the threads
  /// with them first. Either gone — deleted, or hidden by a block — and the
  /// discussion opens as it is, saying the content is no longer available
  /// (Anas: C7 is for a post that's gone, which the post's own read shows).
  /// Anything else that fails is the error, whose retry lands again.
  @protected
  Future<CommunityCommentsState> landOn(
    CommunityLanding target,
    Future<CommentsPage> firstPage,
  ) async {
    final (comment, reply, page) = await (
      getComment(target.commentId),
      _replyOf(target.replyId),
      firstPage,
    ).wait;
    final shown = _valueOf(page);
    final failures = [_failureOf(comment), _failureOf(reply)].nonNulls;
    if (shown == null || (failures.isNotEmpty && !failures.any(_isGone))) {
      return state.copyWith(status: CommunityCommentsStatus.failure);
    }
    pendingLanding = null;
    if (failures.isNotEmpty) {
      return firstPageState(
        shown,
      ).withEvent(CommunityCommentsEvent.contentGone);
    }
    return _landed(
      _valueOf(comment)!,
      _valueOf<CommunityComment?>(reply),
      shown,
    );
  }

  /// The highlight's moment is over.
  void clearHighlight() {
    if (state.highlightId != null) emit(state.withHighlight(null));
  }

  CommunityCommentsState _landed(
    CommunityComment comment,
    CommunityComment? reply,
    CommunityPage<CommunityComment> page,
  ) => state
      .copyWith(
        status: CommunityCommentsStatus.loaded,
        threads: landedThreads(comment, reply, page),
        page: page.pageNumber,
        hasMore: page.hasMore,
      )
      .withHighlight(reply?.id ?? comment.id);

  Future<Either<Failure, CommunityComment?>> _replyOf(int? replyId) async =>
      replyId == null ? const Right(null) : await getComment(replyId);

  static Failure? _failureOf<T>(Either<Failure, T> result) =>
      result.fold((failure) => failure, (_) => null);

  static T? _valueOf<T>(Either<Failure, T> result) =>
      result.fold((_) => null, (value) => value);

  static bool _isGone(Failure failure) =>
      failure is CodedServerFailure &&
      (failure.errorCode == CommunityErrorCodes.commentNotFound ||
          failure.errorCode == CommunityErrorCodes.postNotFound);
}

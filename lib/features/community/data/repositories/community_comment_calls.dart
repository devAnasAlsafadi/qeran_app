import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/comment_submit_outcome.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/community_like_state.dart';
import '../../domain/entities/community_page.dart';
import '../datasources/community_remote_datasource.dart';
import 'community_failure_classifier.dart';
import 'community_post_changes.dart';

/// The repository's comment and reply calls: read, like, write and delete.
/// A comments read or a comment on a post that's gone announces the post
/// gone, as the post's own calls do.
mixin CommunityCommentCalls on BaseRepository {
  @protected
  CommunityRemoteDataSource get dataSource;

  @protected
  CommunityPostChanges get changes;

  Future<Either<Failure, CommunityLikeState>> setCommentLike(
    int commentId, {
    required bool liked,
  }) => executeApiCall(
    () async =>
        (await dataSource.setCommentLike(commentId, liked: liked)).toEntity(),
  );

  Future<Either<Failure, CommunityPage<CommunityComment>>> getComments(
    int postId, {
    required int page,
    required int pageSize,
  }) async {
    final result = await executeApiCall(() async {
      final model = await dataSource.getComments(
        postId,
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity((m) => m.toEntity());
    });
    changes.goneIf(postId, result);
    return result;
  }

  Future<Either<Failure, CommunityPage<CommunityComment>>> getReplies(
    int commentId, {
    required int page,
    required int pageSize,
  }) => executeApiCall(() async {
    final model = await dataSource.getReplies(
      commentId,
      page: page,
      pageSize: pageSize,
    );
    return model.toEntity((m) => m.toEntity());
  });

  Future<Either<Failure, CommunityComment>> getComment(int commentId) =>
      executeApiCall(
        () async => (await dataSource.getComment(commentId)).toEntity(),
      );

  Future<Either<Failure, CommentSubmitOutcome>> createComment(
    int postId,
    String text,
  ) async {
    final result = await executeApiCall(
      () => dataSource.createComment(postId, text),
    );
    changes.goneIf(postId, result);
    return commentSubmitOutcomeOf(result, isReply: false);
  }

  Future<Either<Failure, CommentSubmitOutcome>> createReply(
    int commentId,
    String text,
  ) async => commentSubmitOutcomeOf(
    await executeApiCall(() => dataSource.createReply(commentId, text)),
    isReply: true,
  );

  Future<Either<Failure, Unit>> deleteComment(int commentId) async =>
      goneCountsAsDeleted(
        await executeApiCall(() async {
          await dataSource.deleteComment(commentId);
          return unit;
        }),
      );
}

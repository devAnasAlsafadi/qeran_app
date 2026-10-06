import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/account_cache.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../domain/entities/comment_submit_outcome.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/community_config.dart';
import '../../domain/entities/community_guidelines.dart';
import '../../domain/entities/guidelines_acceptance.dart';
import '../../domain/entities/community_like_state.dart';
import '../../domain/entities/community_page.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_post_change.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_datasource.dart';
import 'community_failure_classifier.dart';
import 'community_post_changes.dart';

class CommunityRepositoryImpl with BaseRepository implements CommunityRepository {
  final CommunityRemoteDataSource _dataSource;

  final _changes = CommunityPostChanges();

  /// The limits, once per account (S15). A failure isn't kept, so the next
  /// screen tries again.
  final AccountCache<CommunityConfig> _config = AccountCache();

  CommunityRepositoryImpl(this._dataSource);

  @override
  Stream<CommunityPostChange> get postChanges => _changes.stream;

  @override
  Future<Either<Failure, CommunityPage<CommunityPost>>> getFeed({
    required int page,
    required int pageSize,
  }) =>
      executeApiCall(() async {
        final model = await _dataSource.getFeed(page: page, pageSize: pageSize);
        return model.toEntity((m) => m.toEntity());
      });

  @override
  Future<Either<Failure, CommunityPost>> getPost(int postId) async {
    final result = await executeApiCall(
      () async => (await _dataSource.getPost(postId)).toEntity(),
    );
    _changes.goneIf(postId, result);
    result.fold((_) {}, (post) => _changes.add(CommunityPostUpdated(post)));
    return result;
  }

  @override
  Future<Either<Failure, CommunityLikeState>> setPostLike(
    int postId, {
    required bool liked,
  }) async {
    final result = await executeApiCall(
      () async =>
          (await _dataSource.setPostLike(postId, liked: liked)).toEntity(),
    );
    _changes.goneIf(postId, result);
    result.fold(
      (_) {},
      (like) => _changes.add(CommunityPostLikeChanged(postId, like)),
    );
    return result;
  }

  @override
  Future<Either<Failure, CommunityLikeState>> setCommentLike(
    int commentId, {
    required bool liked,
  }) =>
      executeApiCall(
        () async => (await _dataSource.setCommentLike(commentId, liked: liked))
            .toEntity(),
      );

  @override
  Future<Either<Failure, CommunityPage<CommunityComment>>> getComments(
    int postId, {
    required int page,
    required int pageSize,
  }) async {
    final result = await executeApiCall(() async {
      final model = await _dataSource.getComments(
        postId,
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity((m) => m.toEntity());
    });
    _changes.goneIf(postId, result);
    return result;
  }

  @override
  Future<Either<Failure, CommunityPage<CommunityComment>>> getReplies(
    int commentId, {
    required int page,
    required int pageSize,
  }) =>
      executeApiCall(() async {
        final model = await _dataSource.getReplies(
          commentId,
          page: page,
          pageSize: pageSize,
        );
        return model.toEntity((m) => m.toEntity());
      });

  @override
  Future<Either<Failure, CommunityComment>> getComment(int commentId) =>
      executeApiCall(
        () async => (await _dataSource.getComment(commentId)).toEntity(),
      );

  @override
  Future<Either<Failure, CommentSubmitOutcome>> createComment(
    int postId,
    String text,
  ) async {
    final result = await executeApiCall(
      () => _dataSource.createComment(postId, text),
    );
    _changes.goneIf(postId, result);
    return commentSubmitOutcomeOf(result, isReply: false);
  }

  @override
  Future<Either<Failure, CommentSubmitOutcome>> createReply(
    int commentId,
    String text,
  ) async =>
      commentSubmitOutcomeOf(
        await executeApiCall(() => _dataSource.createReply(commentId, text)),
        isReply: true,
      );

  @override
  Future<Either<Failure, Unit>> deleteComment(int commentId) async =>
      goneCountsAsDeleted(await executeApiCall(() async {
        await _dataSource.deleteComment(commentId);
        return unit;
      }));

  @override
  Future<Either<Failure, CommunityConfig>> getConfig() => _config.get(
    () => executeApiCall(() async => (await _dataSource.getConfig()).toEntity()),
  );

  /// The account changed: the next account reads the limits again.
  void forgetAccount() => _config.forget();

  @override
  Future<Either<Failure, CommunityGuidelines>> getGuidelines() =>
      executeApiCall(() async => (await _dataSource.getGuidelines()).toEntity());

  @override
  Future<Either<Failure, GuidelinesAcceptance>> acceptGuidelines(
    int version,
  ) async => guidelinesAcceptanceOf(
    await executeApiCall(() => _dataSource.acceptGuidelines(version)),
  );

  @override
  Future<Either<Failure, void>> reportContent(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) => executeApiCall(
    () => _dataSource.reportContent(target, reason: reason, note: note),
  );

  @override
  Future<Either<Failure, void>> blockMember(String userId) =>
      executeApiCall(() => _dataSource.blockMember(userId));
}

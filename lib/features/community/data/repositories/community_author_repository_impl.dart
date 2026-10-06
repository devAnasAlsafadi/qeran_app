import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/community_flagged_item.dart';
import '../../domain/entities/community_page.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_post_change.dart';
import '../../domain/entities/post_publish_outcome.dart';
import '../../domain/repositories/community_author_repository.dart';
import '../datasources/community_author_remote_datasource.dart';
import '../error_codes.dart';
import 'community_failure_classifier.dart';
import 'community_post_changes.dart';
import 'post_publish_classifier.dart';

class CommunityAuthorRepositoryImpl
    with BaseRepository
    implements CommunityAuthorRepository {
  final CommunityAuthorRemoteDataSource _dataSource;

  /// The app's one stream, shared with `CommunityRepositoryImpl`.
  final CommunityPostChanges _changes;

  CommunityAuthorRepositoryImpl(
    this._dataSource, {
    required CommunityPostChanges changes,
  }) : _changes = changes;

  @override
  Future<Either<Failure, CommunityPage<CommunityPost>>> getMyPosts({
    required int page,
    required int pageSize,
  }) => executeApiCall(() async {
    final model = await _dataSource.getMyPosts(page: page, pageSize: pageSize);
    return model.toEntity((m) => m.toEntity());
  });

  @override
  Future<Either<Failure, PostPublishOutcome>> createPost({
    required String text,
    required String clientRequestId,
  }) async {
    final result = await executeApiCall(
      () async => (await _dataSource.createPost(
        text: text,
        clientRequestId: clientRequestId,
      )).toEntity(),
    );
    result.fold((_) {}, (post) => _changes.add(CommunityPostCreated(post)));
    return postPublishOutcomeOf(result);
  }

  /// Gone already (`POST_NOT_FOUND`) is what she asked for: either way the
  /// post leaves every list and an open post screen.
  @override
  Future<Either<Failure, Unit>> deletePost(int postId) async {
    final result = await executeApiCall(() async {
      await _dataSource.deletePost(postId);
      return unit;
    });
    final deleted = result.fold(
      (failure) =>
          communityErrorCode(failure) == CommunityErrorCodes.postNotFound,
      (_) => true,
    );
    if (!deleted) return result;
    _changes.add(CommunityPostGone(postId));
    return const Right(unit);
  }

  /// A row with no flag at all has nothing to keep or delete: left out.
  @override
  Future<Either<Failure, CommunityPage<CommunityFlaggedItem>>> getFlags({
    required int page,
    required int pageSize,
  }) => executeApiCall(() async {
    final model = await _dataSource.getFlags(page: page, pageSize: pageSize);
    final rows = model.toEntity((m) => m.toEntity());
    return CommunityPage(
      items: rows.items.nonNulls.toList(growable: false),
      pageNumber: rows.pageNumber,
      pageSize: rows.pageSize,
      totalCount: rows.totalCount,
      totalPages: rows.totalPages,
    );
  });

  @override
  Future<Either<Failure, Unit>> dismissFlag(int flagId) =>
      executeApiCall(() async {
        await _dataSource.dismissFlag(flagId);
        return unit;
      });
}

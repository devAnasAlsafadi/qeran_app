import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/usecases/get_community_feed_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/set_post_like_usecase.dart';
import 'package:qeran/features/community/domain/usecases/watch_community_post_changes_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';

import '../../../fixtures/community_post_fixtures.dart';

class _MockGetFeed extends Mock implements GetCommunityFeedUseCase {}

class _MockSetLike extends Mock implements SetPostLikeUseCase {}

class _MockGetPost extends Mock implements GetCommunityPostUseCase {}

class _MockWatch extends Mock implements WatchCommunityPostChangesUseCase {}

/// A feed cubit over scripted use cases, and the repository's change stream.
class FeedHarness {
  FeedHarness() {
    when(() => watch()).thenAnswer((_) => changes.stream);
    cubit = CommunityFeedCubit(
      getFeed: getFeed.call,
      getPost: getPost,
      setPostLike: setLike,
      watchChanges: watch,
    );
  }

  final getFeed = _MockGetFeed();
  final getPost = _MockGetPost();
  final setLike = _MockSetLike();
  final watch = _MockWatch();
  final changes = StreamController<CommunityPostChange>.broadcast();
  late final CommunityFeedCubit cubit;

  /// [page] answers with [posts]; there are [totalPages] in all.
  void page(int page, List<CommunityPost> posts, {int totalPages = 1}) =>
      when(() => getFeed(page: page)).thenAnswer(
        (_) async => Right(
          CommunityPage(
            items: posts,
            pageNumber: page,
            pageSize: 20,
            totalCount: posts.length,
            totalPages: totalPages,
          ),
        ),
      );

  /// [page] fails with [failure].
  void pageFails(int page, [Failure failure = const OfflineFailure()]) =>
      when(() => getFeed(page: page)).thenAnswer(
        (_) async => Left<Failure, CommunityPage<CommunityPost>>(failure),
      );

  /// A like or unlike of [postId] answers with [answer].
  void likeAnswers(int postId, Either<Failure, CommunityLikeState> answer) =>
      when(
        () => setLike(postId, liked: any(named: 'liked')),
      ).thenAnswer((_) async => answer);

  Future<void> dispose() async {
    await cubit.close();
    await changes.close();
  }
}

/// Posts [from]..[to], newest first.
List<CommunityPost> posts(int from, int to) => [
  for (var id = from; id <= to; id++) testPost(id: id),
];

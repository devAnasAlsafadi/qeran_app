import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/usecases/get_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/set_post_like_usecase.dart';
import 'package:qeran/features/community/domain/usecases/watch_community_post_changes_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_state.dart';

class _MockGetPost extends Mock implements GetCommunityPostUseCase {}

class _MockSetLike extends Mock implements SetPostLikeUseCase {}

class _MockWatch extends Mock implements WatchCommunityPostChangesUseCase {}

/// `POST_NOT_FOUND`, as the server answers for a post that's gone.
const postNotFound = CodedServerFailure(
  message: 'x',
  errorCode: 'POST_NOT_FOUND',
);

/// A post cubit for post 1 — opened with the feed's copy [post], or
/// without one — over scripted use cases and the repository's stream.
class PostHarness {
  PostHarness({CommunityPost? post}) {
    when(() => watch()).thenAnswer((_) => changes.stream);
    cubit = CommunityPostCubit(
      postId: 1,
      post: post,
      getPost: getPost,
      setPostLike: setLike,
      watchChanges: watch,
    );
  }

  final getPost = _MockGetPost();
  final setLike = _MockSetLike();
  final watch = _MockWatch();
  final changes = StreamController<CommunityPostChange>.broadcast();
  late final CommunityPostCubit cubit;

  void readAnswers(Either<Failure, CommunityPost> answer) =>
      when(() => getPost(1)).thenAnswer((_) async => answer);

  void likeAnswers(Either<Failure, CommunityLikeState> answer) => when(
    () => setLike(1, liked: any(named: 'liked')),
  ).thenAnswer((_) async => answer);

  /// The post on screen.
  CommunityPost get post => (cubit.state as CommunityPostReady).post;

  /// [change] on the repository's stream, delivered.
  Future<void> announce(CommunityPostChange change) async {
    changes.add(change);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await cubit.close();
    await changes.close();
  }
}

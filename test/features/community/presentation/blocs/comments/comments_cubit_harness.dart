import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/usecases/get_comment_replies_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_post_comments_usecase.dart';
import 'package:qeran/features/community/domain/usecases/set_comment_like_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_cubit.dart';

import '../../../fixtures/community_comment_fixtures.dart';

class _MockGetComments extends Mock implements GetPostCommentsUseCase {}

class _MockGetReplies extends Mock implements GetCommentRepliesUseCase {}

class _MockSetLike extends Mock implements SetCommentLikeUseCase {}

typedef CommentsAnswer = Either<Failure, CommunityPage<CommunityComment>>;

/// A comments cubit for post 1 over scripted use cases.
class CommentsHarness {
  CommentsHarness() {
    cubit = CommunityCommentsCubit(
      postId: 1,
      getComments: getComments,
      getReplies: getReplies,
      setCommentLike: setLike,
    );
  }

  final getComments = _MockGetComments();
  final getReplies = _MockGetReplies();
  final setLike = _MockSetLike();
  late final CommunityCommentsCubit cubit;

  /// Page [page] of the comments answers with [items], of [totalPages].
  void page(int page, List<CommunityComment> items, {int totalPages = 1}) =>
      when(() => getComments(1, page: page)).thenAnswer(
        (_) async =>
            Right(commentPage(items, page: page, totalPages: totalPages)),
      );

  void pageFails(int page) => when(
    () => getComments(1, page: page),
  ).thenAnswer((_) async => const Left(OfflineFailure()));

  /// Page [page] of [commentId]'s replies answers with [items]; there are
  /// [totalCount] in [totalPages] pages.
  void replies(
    int commentId,
    int page,
    List<CommunityComment> items, {
    int totalPages = 1,
    int? totalCount,
  }) => when(() => getReplies(commentId, page: page)).thenAnswer(
    (_) async => Right(
      commentPage(
        items,
        page: page,
        totalPages: totalPages,
        totalCount: totalCount,
      ),
    ),
  );

  void repliesFail(int commentId, int page) => when(
    () => getReplies(commentId, page: page),
  ).thenAnswer((_) async => const Left(OfflineFailure()));

  void likeAnswers(int commentId, Either<Failure, CommunityLikeState> answer) =>
      when(
        () => setLike(commentId, liked: any(named: 'liked')),
      ).thenAnswer((_) async => answer);

  CommentThread thread(int commentId) =>
      cubit.state.threads.firstWhere((t) => t.id == commentId);

  List<int> get ids => [for (final t in cubit.state.threads) t.id];

  Future<void> dispose() => cubit.close();
}

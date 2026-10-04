import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/usecases/create_community_comment_usecase.dart';
import 'package:qeran/features/community/domain/usecases/create_community_reply_usecase.dart';
import 'package:qeran/features/community/domain/usecases/delete_community_comment_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_comment_replies_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_comment_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_post_comments_usecase.dart';
import 'package:qeran/features/community/domain/usecases/set_comment_like_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_cubit.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import '../../../fixtures/community_post_fixtures.dart';

class _MockGetComments extends Mock implements GetPostCommentsUseCase {}

class _MockGetReplies extends Mock implements GetCommentRepliesUseCase {}

class _MockSetLike extends Mock implements SetCommentLikeUseCase {}

class _MockCreateComment extends Mock
    implements CreateCommunityCommentUseCase {}

class _MockCreateReply extends Mock implements CreateCommunityReplyUseCase {}

class _MockGetPost extends Mock implements GetCommunityPostUseCase {}

class _MockDelete extends Mock implements DeleteCommunityCommentUseCase {}

class _MockGetComment extends Mock implements GetCommunityCommentUseCase {}

typedef CommentsAnswer = Either<Failure, CommunityPage<CommunityComment>>;

/// A comments cubit for post 1 over scripted use cases — opened at
/// [landing], when there is one.
class CommentsHarness {
  CommentsHarness({CommunityLanding? landing}) {
    cubit = CommunityCommentsCubit(
      postId: 1,
      getComments: getComments,
      getReplies: getReplies,
      setCommentLike: setLike,
      createComment: createComment,
      createReply: createReply,
      deleteComment: delete,
      getPost: getPost,
      getComment: getComment,
      landing: landing,
    );
    when(() => getPost(1)).thenAnswer((_) async => Right(testPost()));
  }

  final getComments = _MockGetComments();
  final getReplies = _MockGetReplies();
  final setLike = _MockSetLike();
  final createComment = _MockCreateComment();
  final createReply = _MockCreateReply();
  final getPost = _MockGetPost();
  final delete = _MockDelete();
  final getComment = _MockGetComment();
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

  /// A comment on post 1 answers with [answer].
  void commentAnswers(Either<Failure, CommentSubmitOutcome> answer) =>
      when(() => createComment(1, any())).thenAnswer((_) async => answer);

  /// A reply under [commentId] answers with [answer].
  void replyAnswers(
    int commentId,
    Either<Failure, CommentSubmitOutcome> answer,
  ) =>
      when(() => createReply(commentId, any())).thenAnswer((_) async => answer);

  /// The comment or reply [id], read on its own, answers with [answer].
  void single(int id, Either<Failure, CommunityComment> answer) =>
      when(() => getComment(id)).thenAnswer((_) async => answer);

  CommentThread thread(int commentId) =>
      cubit.state.threads.firstWhere((t) => t.id == commentId);

  List<int> get ids => [for (final t in cubit.state.threads) t.id];

  Future<void> dispose() => cubit.close();
}

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../entities/comment_submit_outcome.dart';
import '../entities/community_comment.dart';
import '../entities/community_config.dart';
import '../entities/community_guidelines.dart';
import '../entities/guidelines_acceptance.dart';
import '../entities/community_like_state.dart';
import '../entities/community_page.dart';
import '../entities/community_post.dart';
import '../entities/community_post_change.dart';

/// Community, one method per contract path (`03-api-contract.md` §3, §4.1).
/// Report and block join in sub-steps 9 and 10, with their content targets.
abstract class CommunityRepository {
  /// 3.1 — every matchmaker's published posts, newest first.
  Future<Either<Failure, CommunityPage<CommunityPost>>> getFeed({
    required int page,
    required int pageSize,
  });

  /// 3.2 — also announces the fresh copy, or that the post is gone, on
  /// [postChanges].
  Future<Either<Failure, CommunityPost>> getPost(int postId);

  /// 3.3 — idempotent both ways; the answer is announced on [postChanges].
  Future<Either<Failure, CommunityLikeState>> setPostLike(
    int postId, {
    required bool liked,
  });

  /// 3.4 — comments and replies.
  Future<Either<Failure, CommunityLikeState>> setCommentLike(
    int commentId, {
    required bool liked,
  });

  /// 3.5 — top-level comments, newest first.
  Future<Either<Failure, CommunityPage<CommunityComment>>> getComments(
    int postId, {
    required int page,
    required int pageSize,
  });

  /// 3.6 — one comment's replies, oldest first.
  Future<Either<Failure, CommunityPage<CommunityComment>>> getReplies(
    int commentId, {
    required int page,
    required int pageSize,
  });

  /// 3.7 — one comment or reply by id (notification landings).
  Future<Either<Failure, CommunityComment>> getComment(int commentId);

  /// 3.8 — gates, filter and rate limit come back as typed outcomes.
  Future<Either<Failure, CommentSubmitOutcome>> createComment(
    int postId,
    String text,
  );

  /// 3.9 — [commentId] must be a top-level comment.
  Future<Either<Failure, CommentSubmitOutcome>> createReply(
    int commentId,
    String text,
  );

  /// 3.10 — deleting a comment deletes its replies.
  Future<Either<Failure, Unit>> deleteComment(int commentId);

  /// 3.11 — fetched once per app session; a failure is retried next time.
  /// [fresh] reads it now — her composer, on every opening (contract §8).
  Future<Either<Failure, CommunityConfig>> getConfig({bool fresh = false});

  /// §4.1 — the member or the matchmaker text, by token.
  Future<Either<Failure, CommunityGuidelines>> getGuidelines();

  /// §4.1 — a [version] that is no longer current is
  /// [GuidelinesAcceptance.outdated], on the Right.
  Future<Either<Failure, GuidelinesAcceptance>> acceptGuidelines(int version);

  /// §5.1 — a post, comment or reply. Gone → `TARGET_CONTENT_NOT_FOUND`.
  Future<Either<Failure, void>> reportContent(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  });

  /// D6 — the same block as a profile's; hides both ways (D23).
  Future<Either<Failure, void>> blockMember(String userId);

  Stream<CommunityPostChange> get postChanges;
}

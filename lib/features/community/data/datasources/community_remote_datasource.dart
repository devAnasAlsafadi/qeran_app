import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../models/community_comment_model.dart';
import '../models/community_config_model.dart';
import '../models/community_guidelines_model.dart';
import '../models/community_like_state_model.dart';
import '../models/community_page_model.dart';
import '../models/community_post_model.dart';

/// Community's transport, method for method with the repository. It returns
/// models and throws only what `HttpConsumer` throws — `CodedServerException`
/// (with the server's `errorCode`), `ServerException`, `OfflineException`.
/// Classifying those into outcomes is the repository's job, so the live API
/// ([CommunityRemoteDataSourceImpl]) and the in-memory mock are swappable.
abstract class CommunityRemoteDataSource {
  Future<CommunityPageModel<CommunityPostModel>> getFeed({
    required int page,
    required int pageSize,
  });

  Future<CommunityPostModel> getPost(int postId);

  Future<CommunityLikeStateModel> setPostLike(int postId, {required bool liked});

  Future<CommunityLikeStateModel> setCommentLike(
    int commentId, {
    required bool liked,
  });

  Future<CommunityPageModel<CommunityCommentModel>> getComments(
    int postId, {
    required int page,
    required int pageSize,
  });

  Future<CommunityPageModel<CommunityCommentModel>> getReplies(
    int commentId, {
    required int page,
    required int pageSize,
  });

  Future<CommunityCommentModel> getComment(int commentId);

  Future<CommunityCommentModel> createComment(int postId, String text);

  Future<CommunityCommentModel> createReply(int commentId, String text);

  Future<void> deleteComment(int commentId);

  Future<CommunityConfigModel> getConfig();

  Future<CommunityGuidelinesModel> getGuidelines();

  Future<void> acceptGuidelines(int version);

  /// `POST reports` with `targetContentType` (§5.1) — Community's own path,
  /// so the dev-flag mock answers it in memory (Q3).
  Future<void> reportContent(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  });

  /// The same `POST block` as a profile's (D6), through Community so the
  /// mock answers it in memory (Q3). Hides both ways (D23).
  Future<void> blockMember(String userId);
}

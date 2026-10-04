import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../community_end_points.dart';
import '../json_parsers.dart';
import '../models/community_comment_model.dart';
import '../models/community_config_model.dart';
import '../models/community_guidelines_model.dart';
import '../models/community_like_state_model.dart';
import '../models/community_page_model.dart';
import '../models/community_post_model.dart';
import 'community_remote_datasource.dart';

/// The live API. Every path is enveloped (`{ status, message, errorCode,
/// data }`): `HttpConsumer` throws on `status: 0` and on any non-2xx with
/// the `errorCode` kept, and a bare 429 arrives as
/// `errors_too_many_requests` — all the repository needs to classify.
class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final ApiConsumer _api;

  CommunityRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _api = apiConsumer;

  @override
  Future<CommunityPageModel<CommunityPostModel>> getFeed({
    required int page,
    required int pageSize,
  }) async =>
      CommunityPageModel.fromJson(
        _data(await _api.get(
          CommunityEndPoints.posts,
          queryParameters: {'page': page, 'pageSize': pageSize},
        )),
        CommunityPostModel.fromJson,
      );

  @override
  Future<CommunityPostModel> getPost(int postId) async =>
      CommunityPostModel.fromJson(
        _data(await _api.get(CommunityEndPoints.post(postId))),
      );

  @override
  Future<CommunityLikeStateModel> setPostLike(
    int postId, {
    required bool liked,
  }) =>
      _like(CommunityEndPoints.postLike(postId), liked: liked);

  @override
  Future<CommunityLikeStateModel> setCommentLike(
    int commentId, {
    required bool liked,
  }) =>
      _like(CommunityEndPoints.commentLike(commentId), liked: liked);

  @override
  Future<CommunityPageModel<CommunityCommentModel>> getComments(
    int postId, {
    required int page,
    required int pageSize,
  }) =>
      _comments(CommunityEndPoints.postComments(postId), page, pageSize);

  @override
  Future<CommunityPageModel<CommunityCommentModel>> getReplies(
    int commentId, {
    required int page,
    required int pageSize,
  }) =>
      _comments(CommunityEndPoints.commentReplies(commentId), page, pageSize);

  @override
  Future<CommunityCommentModel> getComment(int commentId) async =>
      CommunityCommentModel.fromJson(
        _data(await _api.get(CommunityEndPoints.comment(commentId))),
      );

  @override
  Future<CommunityCommentModel> createComment(int postId, String text) =>
      _send(CommunityEndPoints.postComments(postId), text);

  @override
  Future<CommunityCommentModel> createReply(int commentId, String text) =>
      _send(CommunityEndPoints.commentReplies(commentId), text);

  @override
  Future<void> deleteComment(int commentId) =>
      _api.delete(CommunityEndPoints.comment(commentId));

  @override
  Future<CommunityConfigModel> getConfig() async =>
      CommunityConfigModel.fromJson(
        _data(await _api.get(CommunityEndPoints.config)),
      );

  @override
  Future<CommunityGuidelinesModel> getGuidelines() async =>
      CommunityGuidelinesModel.fromJson(
        _data(await _api.get(CommunityEndPoints.guidelines)),
      );

  @override
  Future<void> acceptGuidelines(int version) => _api.post(
        CommunityEndPoints.acceptGuidelines,
        body: {'version': version},
      );

  @override
  Future<void> reportContent(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) {
    final trimmed = note?.trim();
    return _api.post(
      EndPoints.reports,
      body: {
        'targetContentType': target.apiType,
        'targetContentId': '${target.id}',
        'reason': reason.apiValue,
        if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      },
    );
  }

  Future<CommunityLikeStateModel> _like(String path, {required bool liked}) async {
    final body = liked ? await _api.put(path) : await _api.delete(path);
    return CommunityLikeStateModel.fromJson(_data(body));
  }

  Future<CommunityPageModel<CommunityCommentModel>> _comments(
    String path,
    int page,
    int pageSize,
  ) async =>
      CommunityPageModel.fromJson(
        _data(await _api.get(
          path,
          queryParameters: {'page': page, 'pageSize': pageSize},
        )),
        CommunityCommentModel.fromJson,
      );

  Future<CommunityCommentModel> _send(String path, String text) async =>
      CommunityCommentModel.fromJson(
        _data(await _api.post(path, body: {'text': text})),
      );

  /// The envelope's `data` object. A success with no object in it is a
  /// server fault, surfaced as an error rather than an empty post or comment.
  static Map<String, dynamic> _data(dynamic body) =>
      parseNullableMap(body is Map ? body['data'] : null) ??
      (throw ServerException(message: LocaleKeys.errors_unexpected));
}

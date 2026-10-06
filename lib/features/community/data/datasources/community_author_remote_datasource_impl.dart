import 'package:qeran/core/api/api_consumer.dart';

import '../community_end_points.dart';
import '../models/community_flagged_item_model.dart';
import '../models/community_page_model.dart';
import '../models/community_post_model.dart';
import 'community_author_remote_datasource.dart';
import 'community_envelope.dart';

/// The live API for the post's author. Enveloped like every Community path.
class CommunityAuthorRemoteDataSourceImpl
    implements CommunityAuthorRemoteDataSource {
  final ApiConsumer _api;

  CommunityAuthorRemoteDataSourceImpl({required ApiConsumer apiConsumer})
    : _api = apiConsumer;

  @override
  Future<CommunityPageModel<CommunityPostModel>> getMyPosts({
    required int page,
    required int pageSize,
  }) async => CommunityPageModel.fromJson(
    await _paged(CommunityEndPoints.myPosts, page, pageSize),
    CommunityPostModel.fromJson,
  );

  @override
  Future<CommunityPostModel> createPost({
    required String text,
    required String clientRequestId,
  }) async => CommunityPostModel.fromJson(
    communityEnvelopeData(
      await _api.post(
        CommunityEndPoints.posts,
        body: {'text': text, 'clientRequestId': clientRequestId},
      ),
    ),
  );

  @override
  Future<void> deletePost(int postId) =>
      _api.delete(CommunityEndPoints.post(postId));

  @override
  Future<CommunityPageModel<CommunityFlaggedItemModel>> getFlags({
    required int page,
    required int pageSize,
  }) async => CommunityPageModel.fromJson(
    await _paged(CommunityEndPoints.myPostFlags, page, pageSize),
    CommunityFlaggedItemModel.fromJson,
  );

  @override
  Future<void> dismissFlag(int flagId) =>
      _api.post(CommunityEndPoints.dismissFlag(flagId));

  Future<Map<String, dynamic>> _paged(
    String path,
    int page,
    int pageSize,
  ) async => communityEnvelopeData(
    await _api.get(path, queryParameters: {'page': page, 'pageSize': pageSize}),
  );
}

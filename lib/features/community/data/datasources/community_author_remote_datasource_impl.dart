import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/progress_uploader.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../community_end_points.dart';
import '../json_parsers.dart';
import '../models/community_flagged_item_model.dart';
import '../models/community_page_model.dart';
import '../models/community_post_model.dart';
import 'community_author_remote_datasource.dart';
import 'community_envelope.dart';

/// The live API for the post's author. Enveloped like every Community path.
class CommunityAuthorRemoteDataSourceImpl
    implements CommunityAuthorRemoteDataSource {
  final ApiConsumer _api;

  /// Her media files, with progress and cancel (6.7).
  final ProgressUploader _uploader;

  CommunityAuthorRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
    required ProgressUploader uploader,
  }) : _api = apiConsumer,
       _uploader = uploader;

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
  Future<String> uploadImage(
    UploadFile file, {
    UploadProgress? onProgress,
    UploadCancel? cancel,
  }) async => _mediaIdOf(
    await _uploader.postFile(
      CommunityEndPoints.mediaImages,
      fieldName: 'image',
      file: file,
      onProgress: onProgress,
      cancel: cancel,
    ),
  );

  @override
  Future<void> deleteMedia(String mediaId) =>
      _api.delete(CommunityEndPoints.media(mediaId));

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

  /// An upload's answer without its id is a server fault, not an upload.
  String _mediaIdOf(dynamic body) =>
      parseNullableString(communityEnvelopeData(body)['mediaId']) ??
      (throw ServerException(message: LocaleKeys.errors_unexpected));

  Future<Map<String, dynamic>> _paged(
    String path,
    int page,
    int pageSize,
  ) async => communityEnvelopeData(
    await _api.get(path, queryParameters: {'page': page, 'pageSize': pageSize}),
  );
}

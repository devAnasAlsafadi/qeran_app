import 'package:qeran/core/domain/upload.dart';

import '../models/community_flagged_item_model.dart';
import '../models/community_page_model.dart';
import '../models/community_post_model.dart';
import '../models/video_upload_grant_model.dart';

/// The post author's transport (contract §5.3, §6): her posts, deleting one,
/// and the flags on comments under them. Throws only what `HttpConsumer`
/// throws; the repository classifies. Only the matchmaker app calls it.
abstract class CommunityAuthorRemoteDataSource {
  /// 6.1 — her posts in every status, newest first.
  Future<CommunityPageModel<CommunityPostModel>> getMyPosts({
    required int page,
    required int pageSize,
  });

  /// 6.2 — her post: its text, her uploaded images in her order or her
  /// video, and [clientRequestId], which makes a repeat of the same request
  /// return the same post instead of a second one.
  Future<CommunityPostModel> createPost({
    required String text,
    required String clientRequestId,
    List<String> imageMediaIds = const [],
    String? videoMediaId,
  });

  /// 6.3 — the post and everything under it.
  Future<void> deletePost(int postId);

  /// 6.7 — one image, before the post is made: its `mediaId` for 6.2.
  /// [file] is named and typed by its bytes.
  Future<String> uploadImage(
    UploadFile file, {
    UploadProgress? onProgress,
    UploadCancel? cancel,
  });

  /// 6.8 — her video's upload grant, for the file that will go up: its
  /// size, length, type and display size (rotation applied).
  Future<VideoUploadGrantModel> requestVideoUpload({
    required int sizeBytes,
    required int durationSeconds,
    required String contentType,
    required int width,
    required int height,
  });

  /// Her video's file ([length] bytes) to Bunny Stream with tus, under 6.8's
  /// grant: from [resumeAt]'s offset while the server still has it.
  /// [onCreated] gets a new upload's URL, for the next retry.
  Future<void> uploadVideo({
    required String path,
    required int length,
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, String> metadata,
    Uri? resumeAt,
    void Function(Uri uploadUrl)? onCreated,
    UploadProgress? onProgress,
    UploadCancel? cancel,
  });

  /// 6.9 — media she uploaded for a post she then cancelled.
  Future<void> deleteMedia(String mediaId);

  /// 5.3 — open flags on her posts, newest report first.
  Future<CommunityPageModel<CommunityFlaggedItemModel>> getFlags({
    required int page,
    required int pageSize,
  });

  /// 5.3 — keep the item: the flag clears for her only.
  Future<void> dismissFlag(int flagId);
}

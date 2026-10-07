import 'package:qeran/core/domain/upload.dart';

import '../models/community_flagged_item_model.dart';
import '../models/community_page_model.dart';
import '../models/community_post_model.dart';

/// The post author's transport (contract §5.3, §6): her posts, deleting one,
/// and the flags on comments under them. Throws only what `HttpConsumer`
/// throws; the repository classifies. Only the matchmaker app calls it.
abstract class CommunityAuthorRemoteDataSource {
  /// 6.1 — her posts in every status, newest first.
  Future<CommunityPageModel<CommunityPostModel>> getMyPosts({
    required int page,
    required int pageSize,
  });

  /// 6.2 — her post: its text, and [clientRequestId], which makes a repeat
  /// of the same request return the same post instead of a second one.
  Future<CommunityPostModel> createPost({
    required String text,
    required String clientRequestId,
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

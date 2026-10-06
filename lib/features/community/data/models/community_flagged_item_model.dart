import '../../domain/entities/community_flagged_item.dart';
import '../json_parsers.dart';
import 'community_comment_model.dart';
import 'community_flag_model.dart';

/// Wire model for a row of `GET community/my-posts/flags` (contract §5.3):
/// `{ flag, comment: Comment, post: { id, textSnippet } }`.
class CommunityFlaggedItemModel {
  final CommunityFlagModel? flag;
  final CommunityCommentModel comment;
  final int postId;
  final String postSnippet;

  const CommunityFlaggedItemModel({
    required this.flag,
    required this.comment,
    required this.postId,
    required this.postSnippet,
  });

  factory CommunityFlaggedItemModel.fromJson(Map<String, dynamic> json) {
    final comment = CommunityCommentModel.fromJson(
      parseNullableMap(json['comment']) ?? const {},
    );
    final post = parseNullableMap(json['post']) ?? const {};
    return CommunityFlaggedItemModel(
      // The row's own flag; the comment's copy if the row left it out.
      flag: CommunityFlagModel.parse(json['flag']) ?? comment.flag,
      comment: comment,
      postId: parseInt(post['id'], fallback: comment.postId),
      postSnippet: parseString(post['textSnippet']),
    );
  }

  /// The row, or null when it carries no flag at all — nothing to keep or
  /// delete, so the list leaves it out.
  CommunityFlaggedItem? toEntity() {
    final flag = this.flag;
    if (flag == null) return null;
    return CommunityFlaggedItem(
      flag: flag.toEntity(),
      comment: comment.toEntity(),
      postId: postId,
      postSnippet: postSnippet,
    );
  }
}

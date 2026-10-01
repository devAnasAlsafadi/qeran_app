import '../../domain/entities/community_comment.dart';
import '../json_parsers.dart';
import 'community_author_model.dart';

/// Wire model for a Comment or a reply (contract §2.4):
/// `{ id, postId, parentCommentId, author, text, likeCount, likedByMe,
/// replyCount, createdAt, isMine, canDelete, canBlock, flag }`. `flag` is the
/// author's only and is parsed in Phase 3.
class CommunityCommentModel {
  final int id;
  final int postId;
  final int? parentCommentId;
  final CommunityAuthorModel author;
  final String text;
  final int likeCount;
  final bool likedByMe;
  final int replyCount;
  final DateTime? createdAt;
  final bool isMine;
  final bool canDelete;
  final bool canBlock;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.parentCommentId,
    required this.author,
    required this.text,
    required this.likeCount,
    required this.likedByMe,
    required this.replyCount,
    required this.createdAt,
    required this.isMine,
    required this.canDelete,
    required this.canBlock,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) =>
      CommunityCommentModel(
        id: parseInt(json['id']),
        postId: parseInt(json['postId']),
        parentCommentId: parseNullableInt(json['parentCommentId']),
        author: CommunityAuthorModel.fromJson(
          parseNullableMap(json['author']) ?? const {},
        ),
        text: parseString(json['text']),
        likeCount: parseInt(json['likeCount']),
        likedByMe: parseBool(json['likedByMe']),
        replyCount: parseInt(json['replyCount']),
        createdAt: parseNullableDateTime(json['createdAt']),
        isMine: parseBool(json['isMine']),
        canDelete: parseBool(json['canDelete']),
        // Absent → false: Block is drawn only when the server says so.
        canBlock: parseBool(json['canBlock']),
      );

  CommunityComment toEntity() => CommunityComment(
        id: id,
        postId: postId,
        parentCommentId: parentCommentId,
        author: author.toEntity(),
        text: text,
        likeCount: likeCount,
        likedByMe: likedByMe,
        replyCount: replyCount,
        createdAt: createdAt,
        isMine: isMine,
        canDelete: canDelete,
        canBlock: canBlock,
      );
}

import '../../domain/entities/community_post.dart';
import '../json_parsers.dart';
import 'community_author_model.dart';
import 'community_media_model.dart';

/// Wire model for a Post (contract §2.2):
/// `{ id, author, text, media: [...], likeCount, likedByMe, commentCount,
/// createdAt, canDelete, status }`.
class CommunityPostModel {
  final int id;
  final CommunityAuthorModel author;
  final String text;
  final List<CommunityMediaModel> media;
  final int likeCount;
  final bool likedByMe;
  final int commentCount;
  final DateTime? createdAt;
  final bool canDelete;
  final String? status;

  const CommunityPostModel({
    required this.id,
    required this.author,
    required this.text,
    required this.media,
    required this.likeCount,
    required this.likedByMe,
    required this.commentCount,
    required this.createdAt,
    required this.canDelete,
    required this.status,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) =>
      CommunityPostModel(
        id: parseInt(json['id']),
        author: CommunityAuthorModel.fromJson(
          parseNullableMap(json['author']) ?? const {},
        ),
        text: parseString(json['text']),
        media: parseMapList(json['media'])
            .map(CommunityMediaModel.fromJson)
            .toList(growable: false),
        likeCount: parseInt(json['likeCount']),
        likedByMe: parseBool(json['likedByMe']),
        commentCount: parseInt(json['commentCount']),
        createdAt: parseNullableDateTime(json['createdAt']),
        canDelete: parseBool(json['canDelete']),
        status: parseNullableString(json['status']),
      );

  CommunityPost toEntity() => CommunityPost(
        id: id,
        author: author.toEntity(),
        text: text,
        media: CommunityMediaModel.postMediaFrom(media),
        likeCount: likeCount,
        likedByMe: likedByMe,
        commentCount: commentCount,
        createdAt: createdAt,
        canDelete: canDelete,
        status: CommunityPostStatus.fromWire(status),
      );
}

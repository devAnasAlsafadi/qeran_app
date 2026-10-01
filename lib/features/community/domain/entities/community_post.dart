import 'package:equatable/equatable.dart';

import 'community_author.dart';
import 'community_media.dart';

/// A post's lifecycle (contract §2.2). Members and other matchmakers only
/// ever receive [published]; the author also sees [processing] (a video still
/// encoding) and [failed]. [unknown] is a value this build doesn't know —
/// never drawn as published by mistake.
enum CommunityPostStatus {
  processing,
  published,
  failed,
  unknown;

  static CommunityPostStatus fromWire(String? raw) =>
      switch (raw?.toLowerCase()) {
        'processing' => processing,
        'published' => published,
        'failed' => failed,
        _ => unknown,
      };
}

/// A matchmaker's post (contract §2.2). [commentCount] counts comments and
/// replies as this viewer can see them, so a block never leaves a count the
/// list can't fill. [canDelete] is true only for the post's author.
class CommunityPost extends Equatable {
  final int id;
  final CommunityAuthor author;
  final String text;
  final CommunityPostMedia media;
  final int likeCount;
  final bool likedByMe;
  final int commentCount;

  /// Null only if the server sent none — the time is then left out, never
  /// invented.
  final DateTime? createdAt;
  final bool canDelete;
  final CommunityPostStatus status;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.text,
    required this.media,
    required this.likeCount,
    required this.likedByMe,
    required this.commentCount,
    this.createdAt,
    required this.canDelete,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        author,
        text,
        media,
        likeCount,
        likedByMe,
        commentCount,
        createdAt,
        canDelete,
        status,
      ];
}

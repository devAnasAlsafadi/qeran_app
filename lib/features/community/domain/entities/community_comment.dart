import 'package:equatable/equatable.dart';

import 'community_author.dart';

/// A comment or a reply — one shape for both (contract §2.4). A reply has a
/// [parentCommentId]; comments and replies share one id space.
///
/// The menu is built from the server's flags: [canDelete] (own item, or any
/// item on the viewer's own post) and [canBlock] (false for a matchmaker
/// author, for oneself, and — D40 — whenever the viewer is a matchmaker).
/// The author-only `flag` is parsed in Phase 3; members never receive it.
class CommunityComment extends Equatable {
  final int id;
  final int postId;
  final int? parentCommentId;
  final CommunityAuthor author;
  final String text;
  final int likeCount;
  final bool likedByMe;

  /// Replies this viewer can see; 0 on a reply.
  final int replyCount;

  /// Null only if the server sent none — the time is then left out, never
  /// invented.
  final DateTime? createdAt;
  final bool isMine;
  final bool canDelete;
  final bool canBlock;

  const CommunityComment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.author,
    required this.text,
    required this.likeCount,
    required this.likedByMe,
    required this.replyCount,
    this.createdAt,
    required this.isMine,
    required this.canDelete,
    required this.canBlock,
  });

  bool get isReply => parentCommentId != null;

  @override
  List<Object?> get props => [
        id,
        postId,
        parentCommentId,
        author,
        text,
        likeCount,
        likedByMe,
        replyCount,
        createdAt,
        isMine,
        canDelete,
        canBlock,
      ];
}

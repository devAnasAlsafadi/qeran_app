import 'package:equatable/equatable.dart';

import '../../../community/domain/entities/community_landing.dart';

/// The post a Community notification is about (contract §7.2), and where in
/// its discussion: at `commentId`, and `replyId` under it, when they're there.
/// Both apps' routers read it here; the ids come as strings in a push and as
/// numbers in the inbox.
class CommunityPostTarget extends Equatable {
  const CommunityPostTarget({required this.postId, this.landing});

  /// From a notification's `data`; null without a post. Never throws.
  static CommunityPostTarget? fromData(Map<String, dynamic> data) {
    final postId = _id(data['postId']);
    if (postId == null) return null;
    final commentId = _id(data['commentId']);
    return CommunityPostTarget(
      postId: postId,
      landing: commentId == null
          ? null
          : CommunityLanding(
              commentId: commentId,
              replyId: _id(data['replyId']),
            ),
    );
  }

  final int postId;

  /// Where in its discussion; none when the payload names no comment.
  final CommunityLanding? landing;

  static int? _id(Object? raw) => int.tryParse(raw?.toString().trim() ?? '');

  @override
  List<Object?> get props => [postId, landing];
}

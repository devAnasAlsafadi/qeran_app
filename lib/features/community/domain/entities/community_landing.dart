import 'package:equatable/equatable.dart';

/// Where a notification lands in a post's discussion (C8): a top-level
/// comment, and — for a reply to it — that reply. Both apps open a post with
/// one.
class CommunityLanding extends Equatable {
  const CommunityLanding({required this.commentId, this.replyId});

  /// The comment whose thread is shown first.
  final int commentId;

  /// The reply under it the notification is about.
  final int? replyId;

  @override
  List<Object?> get props => [commentId, replyId];
}

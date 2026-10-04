import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/community_comment.dart';

/// Where a comment's replies stand (C2).
enum RepliesStatus {
  /// None shown yet; the link offers them when there are any.
  collapsed,

  /// A page of them is on its way.
  loading,

  /// At least one page is shown.
  open,

  /// The last page asked for failed: its retry asks again.
  failed,
}

/// A comment or reply the member sent from this screen that isn't settled:
/// on its way (D5, D10), or failed with its retry (D7).
enum CommentDelivery { pending, failed }

/// A top-level comment and the replies shown under it (oldest first).
class CommentThread extends Equatable {
  final CommunityComment comment;

  /// The server's replies, a page at a time, oldest first.
  final List<CommunityComment> replies;

  /// What a landing (C8) shows before any page: the reply the notification
  /// is about. The page that brings it puts it in [replies], in its place.
  final List<CommunityComment> landed;

  /// The member's own replies sent from this screen, after the rest — on
  /// their way, failed, or posted.
  final List<CommunityComment> mine;
  final RepliesStatus repliesStatus;

  /// The last page of replies loaded (1-based; 0 before the first).
  final int repliesPage;

  /// How many replies the last page said there are; before any page, the
  /// comment's own count stands in.
  final int? repliesTotal;
  final bool hasMoreReplies;

  const CommentThread(
    this.comment, {
    this.replies = const [],
    this.landed = const [],
    this.mine = const [],
    this.repliesStatus = RepliesStatus.collapsed,
    this.repliesPage = 0,
    this.repliesTotal,
    this.hasMoreReplies = false,
  });

  int get id => comment.id;

  /// Replies the member hasn't been shown — the count on the link. The
  /// member's posted replies are counted in the totals and shown already.
  int get hiddenReplies {
    final posted = mine.where((reply) => reply.id > 0).length;
    final total = repliesTotal ?? comment.replyCount;
    return max(total - replies.length - landed.length - posted, 0);
  }

  /// Whether the link offers replies: any not shown yet — before the first
  /// page, then while the server has more. The member's own reply, posted
  /// before any page, is counted and already shown.
  bool get offersReplies =>
      hiddenReplies > 0 && (repliesPage == 0 || hasMoreReplies);

  CommentThread copyWith({
    CommunityComment? comment,
    List<CommunityComment>? replies,
    List<CommunityComment>? landed,
    List<CommunityComment>? mine,
    RepliesStatus? repliesStatus,
    int? repliesPage,
    int? repliesTotal,
    bool? hasMoreReplies,
  }) => CommentThread(
    comment ?? this.comment,
    replies: replies ?? this.replies,
    landed: landed ?? this.landed,
    mine: mine ?? this.mine,
    repliesStatus: repliesStatus ?? this.repliesStatus,
    repliesPage: repliesPage ?? this.repliesPage,
    repliesTotal: repliesTotal ?? this.repliesTotal,
    hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
  );

  @override
  List<Object?> get props => [
    comment,
    replies,
    landed,
    mine,
    repliesStatus,
    repliesPage,
    repliesTotal,
    hasMoreReplies,
  ];
}

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

/// A top-level comment and the replies shown under it (oldest first).
class CommentThread extends Equatable {
  final CommunityComment comment;
  final List<CommunityComment> replies;
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
    this.repliesStatus = RepliesStatus.collapsed,
    this.repliesPage = 0,
    this.repliesTotal,
    this.hasMoreReplies = false,
  });

  int get id => comment.id;

  /// Replies the member hasn't been shown — the count on the link.
  int get hiddenReplies =>
      max((repliesTotal ?? comment.replyCount) - replies.length, 0);

  /// Whether the link offers replies: any at all before the first page,
  /// then more of them while the server has more.
  bool get offersReplies => repliesPage == 0
      ? comment.replyCount > 0
      : hasMoreReplies && hiddenReplies > 0;

  CommentThread copyWith({
    CommunityComment? comment,
    List<CommunityComment>? replies,
    RepliesStatus? repliesStatus,
    int? repliesPage,
    int? repliesTotal,
    bool? hasMoreReplies,
  }) => CommentThread(
    comment ?? this.comment,
    replies: replies ?? this.replies,
    repliesStatus: repliesStatus ?? this.repliesStatus,
    repliesPage: repliesPage ?? this.repliesPage,
    repliesTotal: repliesTotal ?? this.repliesTotal,
    hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
  );

  @override
  List<Object?> get props => [
    comment,
    replies,
    repliesStatus,
    repliesPage,
    repliesTotal,
    hasMoreReplies,
  ];
}

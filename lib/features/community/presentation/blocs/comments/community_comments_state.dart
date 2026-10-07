import 'package:equatable/equatable.dart';

import 'comment_thread.dart';

enum CommunityCommentsStatus {
  /// The first page is on its way: the skeleton rows (C5).
  loading,

  /// At least one comment (C1).
  loaded,

  /// The post has no comments this member can see (C4).
  empty,

  /// The first page failed: the error with its retry (C6).
  failure,
}

/// One-shot messages for the post screen, told apart by
/// [CommunityCommentsState.eventVersion].
enum CommunityCommentsEvent {
  none,

  /// A comment's like didn't save and was taken back.
  likeFailed,

  /// A member who can't take part yet tapped Like on a comment (D9).
  readOnlyLike,

  /// The member's comment — with its replies — is deleted (E9).
  deleted,

  /// The member's reply is deleted (E9, S14).
  deletedReply,

  /// A delete didn't go through; the row stays (E10).
  deleteFailed,

  /// The member's reply couldn't be deleted; it stays (E10, S14).
  deleteReplyFailed,

  /// The comment or reply a notification is about is gone — deleted, or
  /// hidden by a block (C8).
  contentGone,

  /// The post's author kept a reported comment: its flag is gone (E3).
  kept,

  /// The same for a reply (Q11).
  keptReply,

  /// Keeping didn't go through; the flag stays.
  keepFailed,
}

class CommunityCommentsState extends Equatable {
  final CommunityCommentsStatus status;

  /// Newest first, each comment once, its replies under it.
  final List<CommentThread> threads;

  /// The last page of comments loaded (1-based).
  final int page;
  final bool hasMore;

  /// The next page is on its way (C3).
  final bool loadingMore;

  /// The next page failed; its retry asks again.
  final bool pageFailed;

  /// A pull to refresh is on its way; the comments stay until it lands.
  final bool refreshing;

  /// What the member sent that isn't settled, by id: on its way, or failed.
  /// Anything not here is posted.
  final Map<int, CommentDelivery> delivery;

  /// The row a landing is about, in gold for a moment (C8, S7).
  final int? highlightId;

  final CommunityCommentsEvent event;
  final int eventVersion;

  const CommunityCommentsState({
    this.status = CommunityCommentsStatus.loading,
    this.threads = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.pageFailed = false,
    this.refreshing = false,
    this.delivery = const {},
    this.highlightId,
    this.event = CommunityCommentsEvent.none,
    this.eventVersion = 0,
  });

  CommunityCommentsState copyWith({
    CommunityCommentsStatus? status,
    List<CommentThread>? threads,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? pageFailed,
    bool? refreshing,
    Map<int, CommentDelivery>? delivery,
  }) => CommunityCommentsState(
    status: status ?? this.status,
    threads: threads ?? this.threads,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    pageFailed: pageFailed ?? this.pageFailed,
    refreshing: refreshing ?? this.refreshing,
    delivery: delivery ?? this.delivery,
    highlightId: highlightId,
    event: event,
    eventVersion: eventVersion,
  );

  /// This state with [id] highlighted, or nothing.
  CommunityCommentsState withHighlight(int? id) => CommunityCommentsState(
    status: status,
    threads: threads,
    page: page,
    hasMore: hasMore,
    loadingMore: loadingMore,
    pageFailed: pageFailed,
    refreshing: refreshing,
    delivery: delivery,
    highlightId: id,
    event: event,
    eventVersion: eventVersion,
  );

  /// This state, telling the screen [next] once.
  CommunityCommentsState withEvent(CommunityCommentsEvent next) =>
      CommunityCommentsState(
        status: status,
        threads: threads,
        page: page,
        hasMore: hasMore,
        loadingMore: loadingMore,
        pageFailed: pageFailed,
        refreshing: refreshing,
        delivery: delivery,
        highlightId: highlightId,
        event: next,
        eventVersion: eventVersion + 1,
      );

  @override
  List<Object?> get props => [
    status,
    threads,
    page,
    hasMore,
    loadingMore,
    pageFailed,
    refreshing,
    delivery,
    highlightId,
    event,
    eventVersion,
  ];
}

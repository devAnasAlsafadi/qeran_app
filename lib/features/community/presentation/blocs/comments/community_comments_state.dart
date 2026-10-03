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

  final CommunityCommentsEvent event;
  final int eventVersion;

  const CommunityCommentsState({
    this.status = CommunityCommentsStatus.loading,
    this.threads = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.pageFailed = false,
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
  }) => CommunityCommentsState(
    status: status ?? this.status,
    threads: threads ?? this.threads,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    pageFailed: pageFailed ?? this.pageFailed,
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
    event,
    eventVersion,
  ];
}

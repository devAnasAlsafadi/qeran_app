import 'package:equatable/equatable.dart';

import '../../../domain/entities/community_post.dart';

enum CommunityFeedStatus {
  /// Nothing asked for yet.
  initial,

  /// The first page is on its way: the skeleton (B3).
  loading,

  /// At least one post (B1).
  loaded,

  /// The server has no posts (B4).
  empty,

  /// The first page failed: the error state with its retry (B5).
  failure,
}

/// One-shot messages for the screen, told apart by [CommunityFeedState.
/// eventVersion].
enum CommunityFeedEvent {
  none,

  /// The like didn't save and was taken back (B13).
  likeFailed,

  /// A member who can't take part yet tapped Like (B12, D9).
  readOnlyLike,
}

class CommunityFeedState extends Equatable {
  final CommunityFeedStatus status;

  /// Newest first, each post once.
  final List<CommunityPost> posts;

  /// The last page loaded (1-based).
  final int page;
  final bool hasMore;

  /// The next page is on its way (B8).
  final bool loadingMore;

  /// The next page failed (B9). Scrolling doesn't ask again; its retry does.
  final bool pageFailed;

  /// A pull to refresh is on its way; the posts stay until it lands (B7).
  final bool refreshing;

  final CommunityFeedEvent event;
  final int eventVersion;

  const CommunityFeedState({
    this.status = CommunityFeedStatus.initial,
    this.posts = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.pageFailed = false,
    this.refreshing = false,
    this.event = CommunityFeedEvent.none,
    this.eventVersion = 0,
  });

  /// The footer's end line (B10): every page is in, and there are posts.
  bool get reachedEnd =>
      status == CommunityFeedStatus.loaded && !hasMore && posts.isNotEmpty;

  CommunityFeedState copyWith({
    CommunityFeedStatus? status,
    List<CommunityPost>? posts,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? pageFailed,
    bool? refreshing,
  }) => CommunityFeedState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    pageFailed: pageFailed ?? this.pageFailed,
    refreshing: refreshing ?? this.refreshing,
    event: event,
    eventVersion: eventVersion,
  );

  /// This state, telling the screen [next] once.
  CommunityFeedState withEvent(CommunityFeedEvent next) => CommunityFeedState(
    status: status,
    posts: posts,
    page: page,
    hasMore: hasMore,
    loadingMore: loadingMore,
    pageFailed: pageFailed,
    refreshing: refreshing,
    event: next,
    eventVersion: eventVersion + 1,
  );

  @override
  List<Object?> get props => [
    status,
    posts,
    page,
    hasMore,
    loadingMore,
    pageFailed,
    refreshing,
    event,
    eventVersion,
  ];
}

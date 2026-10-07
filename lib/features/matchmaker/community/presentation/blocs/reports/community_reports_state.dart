import 'package:equatable/equatable.dart';
import 'package:qeran/features/community/domain/entities/community_flagged_item.dart';

enum CommunityReportsStatus { loading, loaded, empty, failure }

/// One-shot messages for «البلاغات», told apart by
/// [CommunityReportsState.eventVersion].
enum CommunityReportsEvent {
  none,

  /// Kept: the flag is cleared and the row leaves (E3, Q11 for a reply).
  kept,
  keptReply,
  keepFailed,

  /// Deleted: the item, and the row, go (E6).
  deleted,
  deletedReply,
  deleteFailed,
  deleteReplyFailed,
}

/// Her open reports, newest report first (E7–E10).
class CommunityReportsState extends Equatable {
  const CommunityReportsState({
    this.status = CommunityReportsStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.answering = const {},
    this.event = CommunityReportsEvent.none,
    this.eventVersion = 0,
  });

  final CommunityReportsStatus status;
  final List<CommunityFlaggedItem> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// The flags she has kept or deleted that the server hasn't answered yet:
  /// their buttons wait.
  final Set<int> answering;
  final CommunityReportsEvent event;
  final int eventVersion;

  CommunityReportsState copyWith({
    CommunityReportsStatus? status,
    List<CommunityFlaggedItem>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Set<int>? answering,
  }) => CommunityReportsState(
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    answering: answering ?? this.answering,
    event: event,
    eventVersion: eventVersion,
  );

  CommunityReportsState withEvent(CommunityReportsEvent next) =>
      CommunityReportsState(
        status: status,
        items: items,
        page: page,
        hasMore: hasMore,
        loadingMore: loadingMore,
        answering: answering,
        event: next,
        eventVersion: eventVersion + 1,
      );

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    hasMore,
    loadingMore,
    answering,
    event,
    eventVersion,
  ];
}

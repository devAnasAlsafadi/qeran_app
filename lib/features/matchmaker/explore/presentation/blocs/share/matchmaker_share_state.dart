import 'package:equatable/equatable.dart';

import '../../../../users/domain/entities/matchmaker_user_row.dart';

/// One-shot result of a send — the sheet reacts on [MatchmakerShareState.eventVersion]
/// change, ignoring [none]. [partial]/[success] both mean ≥1 share landed.
enum ShareSendOutcome { none, success, partial, failure }

/// State for the Share recipient picker — the matchmaker's own APPROVED users
/// (unsubscribed + subscribed, aggregated; pending excluded), infinite-scroll
/// paginated, with a multi-selection set. The send orchestration is added in a
/// later sub-step.
class MatchmakerShareState extends Equatable {
  final List<MatchmakerUserRow> recipients;

  /// Initial load (first page) in flight.
  final bool loading;

  /// A subsequent page is loading.
  final bool loadingMore;

  /// Initial-load error (the list is empty); null otherwise.
  final String? errorMessage;

  /// More pages remain (across either approved list).
  final bool hasMore;

  /// Selected recipient userIds.
  final Set<String> selected;

  /// A send is in flight (drives the Send-button loader + disables the row).
  final bool sending;

  /// One-shot send result + tally, signalled via [eventVersion].
  final ShareSendOutcome outcome;
  final int sharedCount;
  final int totalCount;
  final int eventVersion;

  const MatchmakerShareState({
    this.recipients = const [],
    this.loading = true,
    this.loadingMore = false,
    this.errorMessage,
    this.hasMore = false,
    this.selected = const {},
    this.sending = false,
    this.outcome = ShareSendOutcome.none,
    this.sharedCount = 0,
    this.totalCount = 0,
    this.eventVersion = 0,
  });

  bool isSelected(String userId) => selected.contains(userId);
  int get selectedCount => selected.length;

  MatchmakerShareState copyWith({
    List<MatchmakerUserRow>? recipients,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
    bool? hasMore,
    Set<String>? selected,
    bool? sending,
    ShareSendOutcome? outcome,
    int? sharedCount,
    int? totalCount,
    int? eventVersion,
  }) {
    return MatchmakerShareState(
      recipients: recipients ?? this.recipients,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      selected: selected ?? this.selected,
      sending: sending ?? this.sending,
      outcome: outcome ?? this.outcome,
      sharedCount: sharedCount ?? this.sharedCount,
      totalCount: totalCount ?? this.totalCount,
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props => [
        recipients,
        loading,
        loadingMore,
        errorMessage,
        hasMore,
        selected,
        sending,
        outcome,
        sharedCount,
        totalCount,
        eventVersion,
      ];
}

import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_match.dart';
import '../../domain/entities/matchmaker_interest_user.dart';
import '../../domain/entities/matchmaker_interests_tab.dart';
import '../../domain/entities/matchmaker_like_activity.dart';

/// Async status for a single interests tab's payload.
enum MatchmakerInterestsAsyncStatus { initial, loading, loaded, failure }

/// One state holding the active tab, the shared [user] header (same across
/// every tab), and three independent async slots. Tabs load lazily; one can be
/// in `failure` while another is `loaded`. The matches slot also carries the
/// [matchesArchived] list — both are fetched together when the matches tab
/// loads. Read-only: there are no action / in-flight fields.
class MatchmakerInterestsState extends Equatable {
  final MatchmakerInterestsTab activeTab;

  /// The viewed user — rendered once above the tabs. `null` until the first
  /// successful page load fills it (every page carries the same `user`).
  final MatchmakerInterestUser? user;

  final MatchmakerInterestsAsyncStatus matchesStatus;
  final List<MatchmakerInterestMatch>? matches;
  final List<MatchmakerInterestArchiveItem>? matchesArchived;
  final String? matchesErrorKey;

  final MatchmakerInterestsAsyncStatus incomingStatus;
  final MatchmakerLikeActivity? incoming;
  final String? incomingErrorKey;

  final MatchmakerInterestsAsyncStatus outgoingStatus;
  final MatchmakerLikeActivity? outgoing;
  final String? outgoingErrorKey;

  const MatchmakerInterestsState({
    this.activeTab = MatchmakerInterestsTab.matches,
    this.user,
    this.matchesStatus = MatchmakerInterestsAsyncStatus.initial,
    this.matches,
    this.matchesArchived,
    this.matchesErrorKey,
    this.incomingStatus = MatchmakerInterestsAsyncStatus.initial,
    this.incoming,
    this.incomingErrorKey,
    this.outgoingStatus = MatchmakerInterestsAsyncStatus.initial,
    this.outgoing,
    this.outgoingErrorKey,
  });

  MatchmakerInterestsState copyWith({
    MatchmakerInterestsTab? activeTab,
    MatchmakerInterestUser? user,
    MatchmakerInterestsAsyncStatus? matchesStatus,
    List<MatchmakerInterestMatch>? matches,
    List<MatchmakerInterestArchiveItem>? matchesArchived,
    String? matchesErrorKey,
    bool clearMatchesError = false,
    MatchmakerInterestsAsyncStatus? incomingStatus,
    MatchmakerLikeActivity? incoming,
    String? incomingErrorKey,
    bool clearIncomingError = false,
    MatchmakerInterestsAsyncStatus? outgoingStatus,
    MatchmakerLikeActivity? outgoing,
    String? outgoingErrorKey,
    bool clearOutgoingError = false,
  }) {
    return MatchmakerInterestsState(
      activeTab: activeTab ?? this.activeTab,
      user: user ?? this.user,
      matchesStatus: matchesStatus ?? this.matchesStatus,
      matches: matches ?? this.matches,
      matchesArchived: matchesArchived ?? this.matchesArchived,
      matchesErrorKey: clearMatchesError
          ? null
          : (matchesErrorKey ?? this.matchesErrorKey),
      incomingStatus: incomingStatus ?? this.incomingStatus,
      incoming: incoming ?? this.incoming,
      incomingErrorKey: clearIncomingError
          ? null
          : (incomingErrorKey ?? this.incomingErrorKey),
      outgoingStatus: outgoingStatus ?? this.outgoingStatus,
      outgoing: outgoing ?? this.outgoing,
      outgoingErrorKey: clearOutgoingError
          ? null
          : (outgoingErrorKey ?? this.outgoingErrorKey),
    );
  }

  @override
  List<Object?> get props => [
        activeTab,
        user,
        matchesStatus,
        matches,
        matchesArchived,
        matchesErrorKey,
        incomingStatus,
        incoming,
        incomingErrorKey,
        outgoingStatus,
        outgoing,
        outgoingErrorKey,
      ];
}

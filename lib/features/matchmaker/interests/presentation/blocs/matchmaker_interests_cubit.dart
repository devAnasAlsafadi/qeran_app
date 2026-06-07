import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interests_tab.dart';
import '../../domain/usecases/get_interest_archived_matches_usecase.dart';
import '../../domain/usecases/get_interest_likes_usecase.dart';
import '../../domain/usecases/get_interest_matches_usecase.dart';
import 'matchmaker_interests_state.dart';

/// Screen-scoped, read-only controller for the matchmaker interests mirror of
/// one viewed user. Each tab is an independent lazy slot — its loader fires the
/// first time the tab is activated, then the result is cached until pull-to-
/// refresh. The matches tab fetches `/matches` and `/matches/archived`
/// concurrently; an archived failure is non-fatal (the active matches still
/// render). No mutating actions — the matchmaker only observes.
class MatchmakerInterestsCubit extends Cubit<MatchmakerInterestsState> {
  final String userId;
  final GetInterestLikesUseCase _getLikes;
  final GetInterestMatchesUseCase _getMatches;
  final GetInterestArchivedMatchesUseCase _getArchived;

  MatchmakerInterestsCubit({
    required this.userId,
    required GetInterestLikesUseCase getLikes,
    required GetInterestMatchesUseCase getMatches,
    required GetInterestArchivedMatchesUseCase getArchivedMatches,
  })  : _getLikes = getLikes,
        _getMatches = getMatches,
        _getArchived = getArchivedMatches,
        super(const MatchmakerInterestsState());

  /// Loads the active tab on mount so the user sees data without an extra tap.
  void primeActiveTab() => _loadTabIfNeeded(state.activeTab);

  void switchTab(MatchmakerInterestsTab tab) {
    if (state.activeTab == tab) return;
    emit(state.copyWith(activeTab: tab));
    _loadTabIfNeeded(tab);
  }

  void _loadTabIfNeeded(MatchmakerInterestsTab tab) {
    switch (tab) {
      case MatchmakerInterestsTab.matches:
        if (state.matchesStatus == MatchmakerInterestsAsyncStatus.initial) {
          loadMatches();
        }
      case MatchmakerInterestsTab.incoming:
        if (state.incomingStatus == MatchmakerInterestsAsyncStatus.initial) {
          loadIncoming();
        }
      case MatchmakerInterestsTab.outgoing:
        if (state.outgoingStatus == MatchmakerInterestsAsyncStatus.initial) {
          loadOutgoing();
        }
    }
  }

  /// Pull-to-refresh entry for the active tab. Always forces a fetch.
  Future<void> refresh() {
    switch (state.activeTab) {
      case MatchmakerInterestsTab.matches:
        return loadMatches();
      case MatchmakerInterestsTab.incoming:
        return loadIncoming();
      case MatchmakerInterestsTab.outgoing:
        return loadOutgoing();
    }
  }

  Future<void> loadMatches() async {
    emit(state.copyWith(
      matchesStatus: MatchmakerInterestsAsyncStatus.loading,
      clearMatchesError: true,
    ));
    // Active + archived in parallel — archived is supplementary.
    final matchesFuture = _getMatches(userId);
    final archivedFuture = _getArchived(userId);
    final matchesResult = await matchesFuture;
    final archivedResult = await archivedFuture;
    if (isClosed) return;
    matchesResult.fold(
      (failure) {
        AppLogger.warning(
          'Interest matches failed — raw="${failure.message}"',
          tag: 'MM-INTERESTS',
        );
        emit(state.copyWith(
          matchesStatus: MatchmakerInterestsAsyncStatus.failure,
          matchesErrorKey: failure.message,
        ));
      },
      (page) {
        final archived = archivedResult.fold(
          (failure) {
            AppLogger.warning(
              'Interest archived matches failed — raw="${failure.message}"',
              tag: 'MM-INTERESTS',
            );
            return const <MatchmakerInterestArchiveItem>[];
          },
          (archivedPage) => archivedPage.data,
        );
        emit(state.copyWith(
          matchesStatus: MatchmakerInterestsAsyncStatus.loaded,
          user: page.user,
          matches: page.data,
          matchesArchived: archived,
          clearMatchesError: true,
        ));
      },
    );
  }

  Future<void> loadIncoming() async {
    emit(state.copyWith(
      incomingStatus: MatchmakerInterestsAsyncStatus.loading,
      clearIncomingError: true,
    ));
    final result =
        await _getLikes(userId, direction: MatchmakerLikeDirection.incoming);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Incoming interest likes failed — raw="${failure.message}"',
          tag: 'MM-INTERESTS',
        );
        emit(state.copyWith(
          incomingStatus: MatchmakerInterestsAsyncStatus.failure,
          incomingErrorKey: failure.message,
        ));
      },
      (page) => emit(state.copyWith(
        incomingStatus: MatchmakerInterestsAsyncStatus.loaded,
        user: page.user,
        incoming: page.data,
        clearIncomingError: true,
      )),
    );
  }

  Future<void> loadOutgoing() async {
    emit(state.copyWith(
      outgoingStatus: MatchmakerInterestsAsyncStatus.loading,
      clearOutgoingError: true,
    ));
    final result =
        await _getLikes(userId, direction: MatchmakerLikeDirection.outgoing);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Outgoing interest likes failed — raw="${failure.message}"',
          tag: 'MM-INTERESTS',
        );
        emit(state.copyWith(
          outgoingStatus: MatchmakerInterestsAsyncStatus.failure,
          outgoingErrorKey: failure.message,
        ));
      },
      (page) => emit(state.copyWith(
        outgoingStatus: MatchmakerInterestsAsyncStatus.loaded,
        user: page.user,
        outgoing: page.data,
        clearOutgoingError: true,
      )),
    );
  }
}

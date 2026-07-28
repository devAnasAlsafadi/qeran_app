import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/profile/domain/entities/profile_fetch_outcome.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_by_id_usecase.dart';

import 'discovery_hydration_state.dart';

/// Fetches the FULL profile for a discovery card so the merged screen can
/// reveal the whole profile inline as the user scrolls.
///
/// The deck payload is a card-sized subset (نبذة عني + the two chip groups);
/// the Q&A groups and نبذة عن شريك الحياة come from
/// `GET /api/discovery/profiles/{userId}` — the same by-id call the standalone
/// full-profile screen already uses, via the same use case.
///
/// Deliberately SEPARATE from [DiscoveryCubit]: the deck, its pagination, the
/// paywall and the daily-limit gating are untouched by hydration, and a
/// hydrate failure must never reach them.
///
/// Contract:
/// * fired when a card becomes CURRENT, not on scroll — by the time the user
///   scrolls down the data is usually already there, so no spinner and no
///   fetch storm while swiping quickly;
/// * cached by id, so undo does not refetch;
/// * a failure is recorded once and degrades to the deck payload forever
///   after. It never blocks like / skip / undo.
class DiscoveryHydrationCubit extends Cubit<DiscoveryHydrationState>
    with SafeEmit<DiscoveryHydrationState> {
  DiscoveryHydrationCubit({required GetProfileByIdUseCase getProfileById})
    : _getProfileById = getProfileById,
      super(const DiscoveryHydrationState());

  final GetProfileByIdUseCase _getProfileById;

  /// Ids with a request in flight — guards the double-fire from
  /// `didChangeDependencies` + `didUpdateWidget` landing in the same frame.
  final Set<String> _inFlight = {};

  Future<void> hydrate(String userId) async {
    if (userId.isEmpty) return;
    if (_inFlight.contains(userId)) return;
    if (state.byId.containsKey(userId)) return;
    if (state.failed.contains(userId)) return;

    _inFlight.add(userId);
    final result = await _getProfileById(userId);
    _inFlight.remove(userId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning(
          'Discovery hydrate failed id=$userId message="${failure.message}" '
          '(card still renders from the deck payload)',
          tag: 'DISCOVERY',
        );
        emit(state.copyWith(failed: {...state.failed, userId}));
      },
      (outcome) {
        switch (outcome) {
          case ProfileFetched(:final profile):
            emit(state.copyWith(byId: {...state.byId, userId: profile}));
          // Not-found / unauthorized are terminal for THIS card only. The deck
          // keeps its own truth; a stale card just shows no extra sections.
          case ProfileNotFoundOutcome():
          case ProfileUnauthorizedOutcome():
            emit(state.copyWith(failed: {...state.failed, userId}));
        }
      },
    );
  }
}

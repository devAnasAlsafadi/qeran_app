import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/usecases/get_matchmaker_dashboard_usecase.dart';
import 'matchmaker_dashboard_state.dart';

/// Drives the matchmaker dashboard stats.
///
/// Session cache: the `MatchmakerHomeScreen` keeps each tab alive via an
/// `IndexedStack`, so this cubit is created once and survives tab hops.
/// [load] therefore no-ops when stats are already in memory; the
/// matchmaker explicitly pulls-to-refresh (or cold-starts the app) to
/// get fresh numbers.
class MatchmakerDashboardCubit extends Cubit<MatchmakerDashboardState> with SafeEmit<MatchmakerDashboardState> {
  final GetMatchmakerDashboardUseCase _getDashboard;

  MatchmakerDashboardCubit({
    required GetMatchmakerDashboardUseCase getDashboard,
  })  : _getDashboard = getDashboard,
        super(const MatchmakerDashboardInitial());

  /// First paint. No-op once loaded (session cache).
  Future<void> load() async {
    if (state is MatchmakerDashboardLoaded) return;
    emit(const MatchmakerDashboardLoading());
    await _fetch();
  }

  /// Pull-to-refresh — always hits the network, keeping current cards
  /// visible while the new numbers arrive.
  Future<void> refresh() async {
    final current = state;
    if (current is MatchmakerDashboardLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _fetch();
  }

  /// Retry after an error — re-enters the loading state.
  Future<void> retry() async {
    emit(const MatchmakerDashboardLoading());
    await _fetch();
  }

  Future<void> _fetch() async {
    final result = await _getDashboard();
    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakerDashboardError(failure.message)),
      (stats) => emit(MatchmakerDashboardLoaded(stats)),
    );
  }
}

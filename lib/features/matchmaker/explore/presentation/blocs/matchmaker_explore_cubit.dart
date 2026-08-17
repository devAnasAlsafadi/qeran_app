import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/matchmaker_explore_user.dart';
import '../../domain/usecases/get_explore_usecase.dart';

/// Owns the paginated explore list plus the active query — `search`, `gender`,
/// and `questionFilters` (`{questionId: [values]}`). Pagination/refresh/
/// load-more come from [PaginatedListCubitMixin]; each query setter resets to
/// page 1 via [loadFirst] so the list re-fetches under the new criteria. The
/// search text is expected pre-debounced by the screen.
class MatchmakerExploreCubit
    extends Cubit<PaginatedListState<MatchmakerExploreUser>>
    with SafeEmit<PaginatedListState<MatchmakerExploreUser>>, PaginatedListCubitMixin<MatchmakerExploreUser> {
  final GetExploreUseCase _getExplore;

  String _search = '';
  Gender? _gender;
  Map<int, List<String>> _questionFilters = const {};
  Map<int, double> _rangeFrom = const {};
  Map<int, double> _rangeTo = const {};

  /// Set by [fetchPage], read by the mixin when it emits — see
  /// [PaginatedListCubitMixin.lastTotalCount].
  int? _totalCount;

  @override
  int? get lastTotalCount => _totalCount;

  MatchmakerExploreCubit({required GetExploreUseCase getExplore})
      : _getExplore = getExplore,
        super(const PaginatedListState());

  @override
  Future<({List<MatchmakerExploreUser> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getExplore(
      page: page,
      pageSize: pageSize,
      search: _search.isEmpty ? null : _search,
      gender: _gender,
      questionFilters: _questionFilters,
      rangeFrom: _rangeFrom,
      rangeTo: _rangeTo,
    );
    return result.fold(
      (failure) => throw _ExploreFetchException(failure.message),
      (pageData) {
        // Recorded before returning so the mixin's emit sees this page's total.
        // A failure leaves the previous value untouched — the throw above means
        // no emit happens, so there is nothing to keep in sync.
        _totalCount = pageData.totalCount;
        return (items: pageData.items, hasMore: pageData.hasMore);
      },
    );
  }

  void setSearch(String value) {
    final v = value.trim();
    if (v == _search) return;
    _search = v;
    _reload();
  }

  void setGender(Gender? gender) {
    if (gender == _gender) return;
    _gender = gender;
    _reload();
  }

  /// Applies the filter sheet's result in one shot: exact-match question
  /// filters + the trimmed numeric ranges (`RangeFrom`/`RangeTo`).
  void setFilters({
    required Map<int, List<String>> questionFilters,
    required Map<int, double> rangeFrom,
    required Map<int, double> rangeTo,
  }) {
    _questionFilters = questionFilters;
    _rangeFrom = rangeFrom;
    _rangeTo = rangeTo;
    _reload();
  }

  /// Clears every narrowing at once — search, gender AND sheet filters — and
  /// reloads a single time.
  ///
  /// Not three setter calls: each of those reloads on its own, so clearing all
  /// three would fire up to three overlapping fetches and the UI would flicker
  /// through intermediate result sets.
  void clearQuery() {
    _search = '';
    _gender = null;
    _questionFilters = const {};
    _rangeFrom = const {};
    _rangeTo = const {};
    _reload();
  }

  /// Re-fetches page 1 under the current query. Drops the in-flight guard so a
  /// rapid query change (gender tap right after a search) is never swallowed.
  void _reload() {
    emit(state.copyWith(isLoading: true, isRefreshing: false, clearError: true));
    fetchPage(1).then((result) {
      if (isClosed) return;
      emit(state.copyWith(
        items: result.items,
        page: 1,
        hasMore: result.hasMore,
        isLoading: false,
        // Threaded here too: this reload is hand-rolled rather than going
        // through the mixin's loaders, so without these two the results-count
        // header would keep showing the PREVIOUS query's total after every
        // search / gender / filter change.
        totalCount: lastTotalCount,
        clearTotalCount: lastTotalCount == null,
      ));
    }).catchError((Object e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    });
  }
}

class _ExploreFetchException implements Exception {
  const _ExploreFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

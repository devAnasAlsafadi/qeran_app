import 'package:flutter_bloc/flutter_bloc.dart';
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
    with PaginatedListCubitMixin<MatchmakerExploreUser> {
  final GetExploreUseCase _getExplore;

  String _search = '';
  Gender? _gender;
  Map<int, List<String>> _questionFilters = const {};
  Map<int, double> _rangeFrom = const {};
  Map<int, double> _rangeTo = const {};

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
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
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

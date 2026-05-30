import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/compatibility_case.dart';
import '../../domain/usecases/get_compatibility_cases_usecase.dart';

/// Owns the single paginated compatibility-cases list. Pagination, refresh
/// and load-more bookkeeping come from [PaginatedListCubitMixin]; this class
/// only wires the fetch under the mixin's throw-on-failure contract.
class MatchmakerCasesListCubit
    extends Cubit<PaginatedListState<CompatibilityCase>>
    with PaginatedListCubitMixin<CompatibilityCase> {
  final GetCompatibilityCasesUseCase _getCases;

  MatchmakerCasesListCubit({required GetCompatibilityCasesUseCase getCases})
      : _getCases = getCases,
        super(const PaginatedListState());

  @override
  Future<({List<CompatibilityCase> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getCases(page: page, pageSize: pageSize);
    // Throw-on-failure: the mixin captures the (already-localized) message
    // into `errorMessage`. `_CasesFetchException.toString()` returns it.
    return result.fold(
      (failure) => throw _CasesFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }
}

class _CasesFetchException implements Exception {
  const _CasesFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

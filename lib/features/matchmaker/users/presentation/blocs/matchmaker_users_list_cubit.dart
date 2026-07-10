import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/matchmaker_user_row.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../../domain/usecases/fetch_matchmaker_users_usecase.dart';

/// One cubit per user list (pending / approved-unsubscribed /
/// approved-subscribed). Pagination, refresh and load-more bookkeeping
/// come from [PaginatedListCubitMixin]; this class only wires the fetch.
class MatchmakerUsersListCubit extends Cubit<PaginatedListState<MatchmakerUserRow>>
    with SafeEmit<PaginatedListState<MatchmakerUserRow>>, PaginatedListCubitMixin<MatchmakerUserRow> {
  final MatchmakerUsersList _list;
  final FetchMatchmakerUsersUseCase _fetchUsers;

  /// Active server-side plan filter (subscribed list only; `null` = All).
  /// Read by [fetchPage] so refresh / load-more keep the same filter.
  int? _planId;

  MatchmakerUsersListCubit({
    required MatchmakerUsersList list,
    required FetchMatchmakerUsersUseCase fetchUsers,
  })  : _list = list,
        _fetchUsers = fetchUsers,
        super(const PaginatedListState());

  /// Applies a plan filter and reloads from page 1. No-op when unchanged so a
  /// redundant chip tap doesn't refetch. Only the subscribed list uses this.
  ///
  /// Clears the current items first so the refetch surfaces the calm list
  /// skeleton (the `isLoading && items.isEmpty` branch) rather than freezing
  /// the previous plan's rows until the new page lands — the view fades
  /// skeleton→list. Distinct from pull-to-refresh, which keeps rows visible.
  Future<void> applyPlanFilter(int? planId) async {
    if (planId == _planId) return;
    _planId = planId;
    emit(state.copyWith(items: const [], clearError: true));
    await loadFirst();
  }

  @override
  Future<({List<MatchmakerUserRow> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _fetchUsers(
      list: _list,
      page: page,
      pageSize: pageSize,
      planId: _planId,
    );
    // The mixin contract is throw-on-failure: it catches and surfaces the
    // message into `errorMessage`. `_UsersFetchException.toString()`
    // returns the clean (already-localized) failure message.
    return result.fold(
      (failure) => throw _UsersFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }
}

class _UsersFetchException implements Exception {
  const _UsersFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

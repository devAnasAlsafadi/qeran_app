import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/matchmaker_colleague.dart';
import '../../domain/usecases/get_colleagues_usecase.dart';

/// Owns the paginated colleague directory — the list a matchmaker browses to
/// START a chat with another matchmaker. Pagination/refresh/load-more come
/// from [PaginatedListCubitMixin]; no realtime (the directory is a static
/// roster, not a live thread list).
class MatchmakerColleaguesDirectoryCubit
    extends Cubit<PaginatedListState<MatchmakerColleague>>
    with SafeEmit<PaginatedListState<MatchmakerColleague>>, PaginatedListCubitMixin<MatchmakerColleague> {
  final GetColleaguesUseCase _getColleagues;

  MatchmakerColleaguesDirectoryCubit({
    required GetColleaguesUseCase getColleagues,
  })  : _getColleagues = getColleagues,
        super(const PaginatedListState());

  @override
  Future<({List<MatchmakerColleague> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getColleagues(page: page, pageSize: pageSize);
    return result.fold(
      (failure) => throw _ColleaguesFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }
}

class _ColleaguesFetchException implements Exception {
  const _ColleaguesFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

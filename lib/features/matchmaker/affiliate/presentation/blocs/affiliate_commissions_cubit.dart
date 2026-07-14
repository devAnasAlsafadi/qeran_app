import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/entities/affiliate_commission.dart';
import '../../domain/usecases/get_affiliate_commissions_usecase.dart';

/// Owns the paginated commission ledger. Pagination / refresh / load-more come
/// from [PaginatedListCubitMixin]; `hasMore` is derived server-side from
/// `page * pageSize < totalCount` (see `AffiliateCommissionsPage`).
class AffiliateCommissionsCubit
    extends Cubit<PaginatedListState<AffiliateCommission>>
    with
        SafeEmit<PaginatedListState<AffiliateCommission>>,
        PaginatedListCubitMixin<AffiliateCommission> {
  final GetAffiliateCommissionsUseCase _getCommissions;

  AffiliateCommissionsCubit({
    required GetAffiliateCommissionsUseCase getCommissions,
  })  : _getCommissions = getCommissions,
        super(const PaginatedListState());

  @override
  Future<({List<AffiliateCommission> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getCommissions(page: page, pageSize: pageSize);
    return result.fold(
      (failure) => throw _CommissionsFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }
}

class _CommissionsFetchException implements Exception {
  const _CommissionsFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

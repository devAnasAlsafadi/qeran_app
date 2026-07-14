import 'package:equatable/equatable.dart';

import 'affiliate_commission.dart';

/// One page of the commission ledger. `hasMore` is derived from the 1-indexed
/// [page] position against [totalCount]: more remain while the rows seen so far
/// (`page * pageSize`) are fewer than the total.
class AffiliateCommissionsPage extends Equatable {
  final List<AffiliateCommission> items;
  final int page;
  final int pageSize;
  final int totalCount;

  const AffiliateCommissionsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  bool get hasMore => page * pageSize < totalCount;

  @override
  List<Object?> get props => [items, page, pageSize, totalCount];
}

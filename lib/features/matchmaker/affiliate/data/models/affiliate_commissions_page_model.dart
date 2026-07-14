import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/affiliate_commissions_page.dart';
import 'affiliate_commission_model.dart';

/// Wire model for a commission-ledger page: `{ items:[...], page, pageSize,
/// totalCount }`. Tolerant of a bare array too (collapsed to a single full
/// page) so one shape drift never blanks the ledger.
class AffiliateCommissionsPageModel {
  final List<AffiliateCommissionModel> items;
  final int page;
  final int pageSize;
  final int totalCount;

  const AffiliateCommissionsPageModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  /// [data] is the already-unwrapped payload — either the paginated object or,
  /// defensively, a bare `List` of rows.
  factory AffiliateCommissionsPageModel.fromData(Object? data) {
    if (data is List) {
      final rows = parseMapList(data)
          .map(AffiliateCommissionModel.fromJson)
          .toList(growable: false);
      return AffiliateCommissionsPageModel(
        items: rows,
        page: 1,
        pageSize: rows.length,
        totalCount: rows.length,
      );
    }
    final map = parseNullableMap(data) ?? const <String, dynamic>{};
    final rows = parseMapList(map['items'])
        .map(AffiliateCommissionModel.fromJson)
        .toList(growable: false);
    return AffiliateCommissionsPageModel(
      items: rows,
      page: parseInt(map['page'], fallback: 1),
      pageSize: parseInt(map['pageSize'], fallback: rows.length),
      totalCount: parseInt(map['totalCount'], fallback: rows.length),
    );
  }

  AffiliateCommissionsPage toEntity() => AffiliateCommissionsPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
      );
}

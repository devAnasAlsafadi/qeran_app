import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/compatibility_cases_page.dart';
import 'compatibility_case_model.dart';

/// Wire model for the paginated `data` object returned by the cases
/// endpoint: `{ data: [...cases], pageNumber, pageSize, totalCount,
/// totalPages }` — the same shape as the M2b users page.
class CompatibilityCasesPageModel {
  final List<CompatibilityCaseModel> items;
  final int pageNumber;
  final int totalPages;

  /// `totalCount` from the wire — the size of the whole filtered result set,
  /// NOT of this page. Parsed via [parseNullableInt] so an absent field stays
  /// null instead of collapsing to 0: a missing total is unknown, and callers
  /// must not render an invented number.
  final int? totalCount;

  const CompatibilityCasesPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
    this.totalCount,
  });

  factory CompatibilityCasesPageModel.fromJson(Map<String, dynamic> json) {
    final cases = parseMapList(json['data'])
        .map(CompatibilityCaseModel.fromJson)
        .toList(growable: false);
    return CompatibilityCasesPageModel(
      items: cases,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
      totalCount: parseNullableInt(json['totalCount']),
    );
  }

  CompatibilityCasesPage toEntity() => CompatibilityCasesPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
        totalCount: totalCount,
      );
}

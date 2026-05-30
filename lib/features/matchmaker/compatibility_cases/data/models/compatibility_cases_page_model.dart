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

  const CompatibilityCasesPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  factory CompatibilityCasesPageModel.fromJson(Map<String, dynamic> json) {
    final cases = parseMapList(json['data'])
        .map(CompatibilityCaseModel.fromJson)
        .toList(growable: false);
    return CompatibilityCasesPageModel(
      items: cases,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
    );
  }

  CompatibilityCasesPage toEntity() => CompatibilityCasesPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}

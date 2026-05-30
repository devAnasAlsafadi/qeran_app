import 'package:equatable/equatable.dart';

import 'compatibility_case.dart';

/// One page of compatibility cases. `hasMore` is derived from the
/// 1-indexed page position against the total page count.
class CompatibilityCasesPage extends Equatable {
  final List<CompatibilityCase> items;
  final int pageNumber;
  final int totalPages;

  const CompatibilityCasesPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages];
}

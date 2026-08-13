import 'package:equatable/equatable.dart';

import 'compatibility_case.dart';

/// One page of compatibility cases. `hasMore` is derived from the
/// 1-indexed page position against the total page count.
class CompatibilityCasesPage extends Equatable {
  final List<CompatibilityCase> items;
  final int pageNumber;
  final int totalPages;

  /// How many cases match the CURRENT server query in total — across every
  /// page, not just this one. Distinct from [items].length, which is only
  /// the slice this page carries.
  ///
  /// Nullable on purpose: it is null when the payload omits `totalCount`.
  /// Per the backend-driven rule we never invent a total — an unknown total
  /// is rendered as "unknown", never as 0 and never as the loaded count.
  final int? totalCount;

  const CompatibilityCasesPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
    this.totalCount,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages, totalCount];
}

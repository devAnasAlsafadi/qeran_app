import 'package:equatable/equatable.dart';

/// User's in-progress selection for one filter question.
///
/// Sealed so the cubit and the payload serializer can exhaustively
/// switch on the variant — adding a new selection shape forces the
/// compiler to point every call site that needs an update.
sealed class DiscoveryFilterSelection extends Equatable {
  const DiscoveryFilterSelection();

  @override
  List<Object?> get props => const [];
}

/// Used by `height` / `weight` questions.
final class RangeSelection extends DiscoveryFilterSelection {
  final int min;
  final int max;

  const RangeSelection({required this.min, required this.max});

  RangeSelection copyWith({int? min, int? max}) {
    return RangeSelection(min: min ?? this.min, max: max ?? this.max);
  }

  @override
  List<Object?> get props => [min, max];
}

/// Used by `select` / `radio` questions — one chosen `value`.
final class SingleValueSelection extends DiscoveryFilterSelection {
  final String value;

  const SingleValueSelection(this.value);

  @override
  List<Object?> get props => [value];
}

/// Used by `checkbox` questions — zero-or-more chosen `value`s.
///
/// An empty list is allowed transiently (the user just deselected the
/// last option); the cubit drops empty multi-selections from the
/// payload so they don't constrain the server.
final class MultiValueSelection extends DiscoveryFilterSelection {
  final List<String> values;

  const MultiValueSelection(this.values);

  @override
  List<Object?> get props => [values];
}

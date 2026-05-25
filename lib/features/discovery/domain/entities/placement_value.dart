import 'package:equatable/equatable.dart';

/// The polymorphic value/display payload of a [PlacementItem].
///
/// Server ships either a `String` or a `List<String>` depending on the
/// item's [PlacementItemType]. Sealed so callers handle both cases with an
/// exhaustive `switch` — no `dynamic`, no scattered runtime checks.
sealed class PlacementValue extends Equatable {
  const PlacementValue();
}

final class PlacementSingle extends PlacementValue {
  final String value;
  const PlacementSingle(this.value);

  @override
  List<Object?> get props => [value];
}

final class PlacementMulti extends PlacementValue {
  final List<String> values;
  const PlacementMulti(this.values);

  @override
  List<Object?> get props => [values];
}

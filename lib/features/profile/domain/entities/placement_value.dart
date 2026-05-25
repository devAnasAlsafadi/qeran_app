import 'package:equatable/equatable.dart';

/// Polymorphic value/display payload of a placement item.
///
/// Backend ships either `String` or `List<String>` for `value` and
/// `display` depending on the item's `type`. Sealing keeps UI rendering
/// exhaustive at the type level — no `dynamic` survives past the
/// model→entity boundary.
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

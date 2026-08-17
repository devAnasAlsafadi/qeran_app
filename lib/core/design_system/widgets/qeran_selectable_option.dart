import 'package:equatable/equatable.dart';

/// One selectable choice for a design-system facet — [QeranFilterChipFacet],
/// [QeranFilterSearchableFacet].
///
/// Deliberately domain-agnostic. The facets are design-system widgets, so they
/// must not know a feature entity: nothing in `lib/core` imports
/// `lib/features`, and these widgets are not going to be the first. Each
/// feature maps its own option type to this at the call site — one `.map()` —
/// which keeps that direction intact while both apps share one widget.
///
/// [value] is the raw token the caller round-trips and is never displayed;
/// [display] is the user-facing label, already localized by whoever supplied it.
class QeranSelectableOption extends Equatable {
  final String value;
  final String display;

  const QeranSelectableOption({required this.value, required this.display});

  @override
  List<Object?> get props => [value, display];
}

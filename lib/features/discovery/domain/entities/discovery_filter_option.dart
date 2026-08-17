import 'package:equatable/equatable.dart';

/// Sort key standing in for an absent `displayPriority`, so unprioritized
/// entries land AFTER every prioritized one (E1) instead of jumping to the front
/// the way a `0` default would.
///
/// `1 << 30` rather than a real infinity: the keys are ints, it survives being
/// compared and added to without overflow on either platform, and it is far
/// outside any ordering a dashboard would plausibly assign.
const int kUnprioritizedOrderKey = 1 << 30;

/// One choice on a select / radio / checkbox filter question.
///
/// `value` is the raw token the server expects in the eventual
/// `QuestionFilters` payload. `display` is the user-facing label
/// (already localized server-side via `Accept-Language`).
class DiscoveryFilterOption extends Equatable {
  final String value;
  final String display;

  /// Dashboard-controlled ordering weight, ascending. Null when the dashboard
  /// hasn't set one — such options sort last (see the sort helper) rather than
  /// jumping to the front as a `0` would.
  final int? displayPriority;

  const DiscoveryFilterOption({
    required this.value,
    required this.display,
    this.displayPriority,
  });

  /// [displayPriority], with absent treated as "after everything".
  int get effectiveOrderKey => displayPriority ?? kUnprioritizedOrderKey;

  DiscoveryFilterOption copyWith({
    String? value,
    String? display,
    int? displayPriority,
  }) => DiscoveryFilterOption(
    value: value ?? this.value,
    display: display ?? this.display,
    displayPriority: displayPriority ?? this.displayPriority,
  );

  @override
  List<Object?> get props => [value, display, displayPriority];
}

import 'package:equatable/equatable.dart';

/// One choice on a select / radio / checkbox filter question.
///
/// `value` is the raw token the server expects in the eventual
/// `QuestionFilters` payload. `display` is the user-facing label
/// (already localized server-side via `Accept-Language`).
class DiscoveryFilterOption extends Equatable {
  final String value;
  final String display;

  const DiscoveryFilterOption({
    required this.value,
    required this.display,
  });

  @override
  List<Object?> get props => [value, display];
}

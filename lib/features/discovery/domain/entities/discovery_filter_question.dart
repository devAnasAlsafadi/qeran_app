import 'package:equatable/equatable.dart';

import 'discovery_filter_option.dart';
import 'filter_question_type.dart';

/// One dynamic filter question returned by `GET /api/discovery/filters`.
///
/// Filters share the questionnaire's question types, so [type] carries
/// the full vocabulary. [isRange] is the backend-confirmed flag that
/// drives range-vs-discrete rendering — checked FIRST so any type
/// (date/height/weight/future) can render as a range when the dashboard
/// flags it. [type] then disambiguates the non-range cases (radio vs
/// checkbox vs text vs interests).
class DiscoveryFilterQuestion extends Equatable {
  /// Server-side question id.
  final int id;

  /// User-facing label (localized server-side via Accept-Language).
  final String label;

  final FilterQuestionType type;

  /// Backend-controlled. When true, the renderer always uses a range
  /// slider regardless of [type].
  final bool isRange;

  /// Backend range bounds. Used by [effectiveMin] / [effectiveMax] when
  /// present.
  final int? minValue;
  final int? maxValue;

  /// Backend-localized unit string (e.g. "سم", "كيلو", "سنة"). Empty
  /// or null when not applicable.
  final String? unit;

  /// Null for ranges; non-null (but possibly empty) for select / radio
  /// / checkbox / interests.
  final List<DiscoveryFilterOption>? options;

  /// Dashboard-controlled ordering weight for the question itself, ascending.
  /// Null → sorts last, preserving the server's original order among peers.
  final int? displayPriority;

  /// Dashboard override for the search-inside-a-facet affordance. Null → the
  /// client keeps inferring it from the option count.
  final bool? isSearchable;

  /// Dashboard override for single-vs-multi selection. Null → the client keeps
  /// inferring it from [type].
  final bool? isMultiSelect;

  const DiscoveryFilterQuestion({
    required this.id,
    required this.label,
    required this.type,
    required this.isRange,
    this.minValue,
    this.maxValue,
    this.unit,
    this.options,
    this.displayPriority,
    this.isSearchable,
    this.isMultiSelect,
  });

  /// Field-wise copy. Nullable fields cannot be cleared through it (a null
  /// argument means "keep") — nothing needs to null one out, and the sort
  /// helper only ever REPLACES [options] with a reordered list.
  DiscoveryFilterQuestion copyWith({
    int? id,
    String? label,
    FilterQuestionType? type,
    bool? isRange,
    int? minValue,
    int? maxValue,
    String? unit,
    List<DiscoveryFilterOption>? options,
    int? displayPriority,
    bool? isSearchable,
    bool? isMultiSelect,
  }) => DiscoveryFilterQuestion(
    id: id ?? this.id,
    label: label ?? this.label,
    type: type ?? this.type,
    isRange: isRange ?? this.isRange,
    minValue: minValue ?? this.minValue,
    maxValue: maxValue ?? this.maxValue,
    unit: unit ?? this.unit,
    options: options ?? this.options,
    displayPriority: displayPriority ?? this.displayPriority,
    isSearchable: isSearchable ?? this.isSearchable,
    isMultiSelect: isMultiSelect ?? this.isMultiSelect,
  );

  /// Prefer backend [minValue] → type-based defaults → generic.
  int get effectiveMin {
    if (minValue != null) return minValue!;
    return switch (type) {
      FilterQuestionType.height => 50,
      FilterQuestionType.weight => 30,
      FilterQuestionType.date => 18,
      _ => 0,
    };
  }

  /// Dashboard flag when set, else the client's type-based inference.
  ///
  /// Lives on the entity for the same reason [effectiveMin] does: both
  /// renderers AND both cubits have to agree, and a getter makes that
  /// structural instead of a convention two duplicated files must uphold.
  ///
  /// The inference is "every option-bearing type is multi": the wire format
  /// has always carried comma-joined values, so single-choice was a client
  /// limitation, never a contract one. [text] never is, and range types never
  /// reach an option facet.
  bool get effectiveIsMultiSelect {
    if (isMultiSelect != null) return isMultiSelect!;
    return switch (type) {
      FilterQuestionType.select ||
      FilterQuestionType.radio ||
      FilterQuestionType.checkbox ||
      FilterQuestionType.interests ||
      FilterQuestionType.unknown => true,
      FilterQuestionType.text ||
      FilterQuestionType.date ||
      FilterQuestionType.height ||
      FilterQuestionType.weight => false,
    };
  }

  /// [displayPriority], with absent treated as "after everything" — see
  /// [kUnprioritizedOrderKey]. Mirrors [DiscoveryFilterOption.effectiveOrderKey]
  /// so questions and their options sort by the same rule.
  int get effectiveOrderKey => displayPriority ?? kUnprioritizedOrderKey;

  /// Dashboard flag when set, else "does this list need a search box?" decided
  /// by option count.
  ///
  /// The dashboard wins ABSOLUTELY: `isSearchable: false` on a 300-option
  /// question renders 300 chips. The threshold is passed IN rather than read
  /// here because it is a design-system number (how many chips read
  /// comfortably) and no domain or data file in this codebase imports the
  /// design system — see [nonSearchableLongLists] for the visibility warning
  /// that covers the disagreement.
  bool effectiveIsSearchable({required int optionCountThreshold}) =>
      isSearchable ?? (options?.length ?? 0) > optionCountThreshold;

  /// True when the dashboard explicitly forbids the search affordance on a list
  /// long enough that the client would have chosen it.
  bool exceedsSearchThresholdWithoutSearch({
    required int optionCountThreshold,
  }) =>
      isSearchable == false &&
      (options?.length ?? 0) > optionCountThreshold;

  /// True when the dashboard explicitly forbids multi-select. Distinct from
  /// `!effectiveIsMultiSelect` — only an EXPLICIT false collapses a seeded
  /// multi-value selection on load.
  bool get forbidsMultiSelect => isMultiSelect == false;

  /// Prefer backend [maxValue] → type-based defaults → generic.
  int get effectiveMax {
    if (maxValue != null) return maxValue!;
    return switch (type) {
      FilterQuestionType.height => 200,
      FilterQuestionType.weight => 200,
      FilterQuestionType.date => 80,
      _ => 100,
    };
  }

  @override
  List<Object?> get props => [
        id,
        label,
        type,
        isRange,
        minValue,
        maxValue,
        unit,
        options,
        displayPriority,
        isSearchable,
        isMultiSelect,
      ];
}

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

  const DiscoveryFilterQuestion({
    required this.id,
    required this.label,
    required this.type,
    required this.isRange,
    this.minValue,
    this.maxValue,
    this.unit,
    this.options,
  });

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
      ];
}

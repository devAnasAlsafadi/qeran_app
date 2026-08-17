import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/filter_question_type.dart';
import '../json_parsers.dart';
import 'discovery_filter_option_model.dart';

class DiscoveryFilterQuestionModel {
  final int questionId;
  final String question;

  /// Raw wire string — mapped to [FilterQuestionType] in [toEntity]
  /// (unknown values collapse to [FilterQuestionType.unknown]).
  final String? type;

  /// Backend flag. When true, renderer uses a range slider regardless
  /// of [type].
  final bool isRange;

  final int? minValue;
  final int? maxValue;
  final String? unit;

  /// Null when the server returns `"options": null` (ranges typically).
  final List<DiscoveryFilterOptionModel>? options;

  /// Dashboard-controlled question ordering weight, ascending.
  final int? displayPriority;

  /// Dashboard override for the searchable-facet affordance.
  final bool? isSearchable;

  /// Dashboard override for single-vs-multi selection.
  final bool? isMultiSelect;

  const DiscoveryFilterQuestionModel({
    required this.questionId,
    required this.question,
    required this.type,
    required this.isRange,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.options,
    this.displayPriority,
    this.isSearchable,
    this.isMultiSelect,
  });

  /// The three dashboard fields are absent on every payload until the backend
  /// rollout lands, so absence stays SILENT — a warning per question per load
  /// would be noise for an expected transition state.
  factory DiscoveryFilterQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return DiscoveryFilterQuestionModel(
      questionId: (json['questionId'] as num?)?.toInt() ?? 0,
      question: json['question']?.toString() ?? '',
      type: json['type'] as String?,
      isRange: json['isRange'] as bool? ?? false,
      minValue: (json['minValue'] as num?)?.toInt(),
      maxValue: (json['maxValue'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      options: rawOptions is List
          ? rawOptions
              .whereType<Map<String, dynamic>>()
              .map(DiscoveryFilterOptionModel.fromJson)
              .toList()
          : null,
      displayPriority: parseNullableInt(json['displayPriority']),
      isSearchable: parseNullableBool(json['isSearchable']),
      isMultiSelect: parseNullableBool(json['isMultiSelect']),
    );
  }

  DiscoveryFilterQuestion toEntity() => DiscoveryFilterQuestion(
        id: questionId,
        label: question,
        type: FilterQuestionType.fromWire(type),
        isRange: isRange,
        minValue: minValue,
        maxValue: maxValue,
        unit: unit,
        options: options?.map((o) => o.toEntity()).toList(),
        displayPriority: displayPriority,
        isSearchable: isSearchable,
        isMultiSelect: isMultiSelect,
      );
}

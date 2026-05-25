/// Filter question types — mirrors the questionnaire's `QuestionType`
/// vocabulary so the same dynamic questions can appear in filters.
///
/// Intentionally NOT imported from `features/questionnaire/` (see
/// [PlacementItemType] for the same precedent in this feature). Sharing
/// the enum would create cross-feature coupling at the data layer.
///
/// New backend strings collapse to [unknown] — the renderer treats
/// `unknown + options` as a single-choice fallback and skips the rest.
enum FilterQuestionType {
  date,
  height,
  weight,
  select,
  checkbox,
  interests,
  text,
  radio,
  unknown;

  static FilterQuestionType fromWire(String? raw) {
    if (raw == null) return FilterQuestionType.unknown;
    return switch (raw.toLowerCase()) {
      'date' => FilterQuestionType.date,
      'height' => FilterQuestionType.height,
      'weight' => FilterQuestionType.weight,
      'select' => FilterQuestionType.select,
      'checkbox' => FilterQuestionType.checkbox,
      'interests' => FilterQuestionType.interests,
      'text' => FilterQuestionType.text,
      'radio' => FilterQuestionType.radio,
      _ => FilterQuestionType.unknown,
    };
  }
}

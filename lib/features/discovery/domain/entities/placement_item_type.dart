/// Type of a single [PlacementItem]'s value/display payload.
///
/// Deliberately NOT reused from the questionnaire's `QuestionType` — the
/// overlap is incidental and coupling Discovery to Questionnaire would be
/// premature. Unknown server strings collapse to [unknown].
enum PlacementItemType {
  select,
  text,
  radio,
  checkbox,
  weight,
  height,
  interests,
  unknown;

  static PlacementItemType fromString(String raw) {
    return switch (raw.toLowerCase()) {
      'select' => PlacementItemType.select,
      'text' => PlacementItemType.text,
      'radio' => PlacementItemType.radio,
      'checkbox' => PlacementItemType.checkbox,
      'weight' => PlacementItemType.weight,
      'height' => PlacementItemType.height,
      'interests' => PlacementItemType.interests,
      _ => PlacementItemType.unknown,
    };
  }
}

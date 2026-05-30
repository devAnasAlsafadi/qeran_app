enum Gender {
  male,
  female;

  String get apiValue => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
  };

  /// Tolerant parse from a wire string (`"Male"` / `"Female"`,
  /// case-insensitive). Returns `null` for absent / unrecognised values so
  /// callers can tell "missing" from a known value — there is intentionally
  /// no `unknown` member (it would break the exhaustive [apiValue] switch).
  static Gender? fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return null;
    }
  }
}

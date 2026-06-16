/// Backend `errorCode` constants for the matchmaker per-case note endpoint.
/// Bare strings (same convention as the user-notes / chat / likes modules) so
/// cubits and tests reference them without importing presentation code.
class CaseNoteErrorCodes {
  CaseNoteErrorCodes._();

  /// PUT with empty / whitespace-only or >2000-char content.
  static const String validationError = 'VALIDATION_ERROR';

  /// The target case id doesn't exist.
  static const String caseNotFound = 'CASE_NOT_FOUND';

  /// This matchmaker is not a party to the case.
  static const String notInvolvedInCase = 'NOT_INVOLVED_IN_CASE';

  /// Auth/role failure on the endpoint.
  static const String unauthorized = 'UNAUTHORIZED';
}

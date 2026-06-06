/// Backend `errorCode` constants for the matchmaker user-notes endpoint.
/// Bare strings (same convention as compatibility-cases / chat / likes) so
/// cubits and tests reference them without importing presentation code.
class MatchmakerNotesErrorCodes {
  MatchmakerNotesErrorCodes._();

  /// PUT with empty / whitespace-only or >2000-char content.
  static const String validationError = 'VALIDATION_ERROR';

  /// The target user id doesn't exist.
  static const String userNotFound = 'USER_NOT_FOUND';

  /// The user isn't assigned to this matchmaker.
  static const String unauthorized = 'UNAUTHORIZED';
}

/// Backend `errorCode` constants for the matchmaker account (`/me`) endpoints.
/// Bare strings (same convention as compatibility-cases / notes) so cubits and
/// tests reference them without importing presentation code.
class MatchmakerAccountErrorCodes {
  MatchmakerAccountErrorCodes._();

  /// Empty / whitespace name, name >100 chars, or a bad image format / size.
  static const String validationError = 'VALIDATION_ERROR';

  /// The signed-in matchmaker account no longer exists.
  static const String userNotFound = 'USER_NOT_FOUND';
}

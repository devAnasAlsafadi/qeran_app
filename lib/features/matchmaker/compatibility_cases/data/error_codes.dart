/// Backend `errorCode` constants for the matchmaker compatibility-cases
/// domain. Kept as bare strings (same convention as the chat / likes
/// modules) so cubits and tests can reference them without importing
/// presentation code.
class CompatibilityCasesErrorCodes {
  CompatibilityCasesErrorCodes._();

  /// Returned by the status POST when the requested formal-request
  /// transition isn't allowed from the current status. The server message
  /// is numeric ("…من الحالة 2 إلى الحالة 2") — surface a local string
  /// instead and refresh the list, since the real status may have moved.
  static const String invalidStatusTransition = 'INVALID_STATUS_TRANSITION';
}

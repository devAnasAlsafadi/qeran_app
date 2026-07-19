/// Backend `errorCode` constants for the questionnaire / submit-answers flow.
/// Kept as bare strings so they can also be referenced from tests without
/// importing presentation code. Classify on these — never the message.
class QuestionnaireErrorCodes {
  QuestionnaireErrorCodes._();

  /// Adults-only gate: the server rejects the WHOLE submission when the
  /// supplied birthdate is under 18. The birthday picker also clamps to 18+
  /// client-side, but the server code is the authoritative gate.
  static const String underageNotAllowed = 'UNDERAGE_NOT_ALLOWED';
}

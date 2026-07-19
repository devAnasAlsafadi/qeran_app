/// Machine-readable `errorCode`s that `POST /api/reports` returns on a failure
/// envelope (`status: 0`). Branch on these — never the Arabic `message`.
class ReportErrorCodes {
  const ReportErrorCodes._();

  /// `reason` missing/invalid, or neither target supplied.
  static const String validationError = 'VALIDATION_ERROR';

  /// The reported user no longer exists (deleted / unavailable). Also returned
  /// neutrally when the target has blocked the reporter — never reveal that.
  static const String targetUserNotFound = 'TARGET_USER_NOT_FOUND';
}

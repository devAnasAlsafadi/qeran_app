/// Machine-readable `errorCode`s the block endpoints return on a failure
/// envelope. Branch on these — never the message.
class BlockErrorCodes {
  const BlockErrorCodes._();

  /// Missing/invalid targetUserId.
  static const String validationError = 'VALIDATION_ERROR';

  /// The target no longer exists — OR the target has blocked the caller. The
  /// backend returns this NEUTRALLY for actions against a blocked user; the UI
  /// must treat it as a plain "unavailable" and NEVER reveal block status.
  static const String targetUserNotFound = 'TARGET_USER_NOT_FOUND';
}

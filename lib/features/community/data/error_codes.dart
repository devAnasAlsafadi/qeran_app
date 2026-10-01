/// Backend `errorCode` constants for Community (contract §9). The repository
/// maps them to typed outcomes; the datasource only passes them through.
class CommunityErrorCodes {
  CommunityErrorCodes._();

  // Gates, in the server's order (contract §4).
  static const String profileNotApproved = 'PROFILE_NOT_APPROVED';
  static const String displayNameRequired = 'DISPLAY_NAME_REQUIRED';
  static const String guidelinesNotAccepted =
      'COMMUNITY_GUIDELINES_NOT_ACCEPTED';
  static const String validationError = 'VALIDATION_ERROR';
  static const String contentNotAllowed = 'CONTENT_NOT_ALLOWED';

  /// Comment / reply limit (5 a minute, 60 an hour), with
  /// `data.retryAfterSeconds`. A bare 429 has no code at all.
  static const String rateLimited = 'RATE_LIMITED';

  // Gone, or hidden by a block — the same neutral answer either way.
  static const String postNotFound = 'POST_NOT_FOUND';
  static const String commentNotFound = 'COMMENT_NOT_FOUND';
  static const String targetContentNotFound = 'TARGET_CONTENT_NOT_FOUND';

  static const String unauthorized = 'UNAUTHORIZED';
  static const String blockNotAllowed = 'BLOCK_NOT_ALLOWED';

  // Media — the matchmaker's composer (Phase 3).
  static const String mediaRequired = 'MEDIA_REQUIRED';
  static const String mediaTooLarge = 'MEDIA_TOO_LARGE';
  static const String mediaTooLong = 'MEDIA_TOO_LONG';
  static const String mediaInvalidType = 'MEDIA_INVALID_TYPE';
  static const String mediaLimitReached = 'MEDIA_LIMIT_REACHED';
  static const String mediaNotFound = 'MEDIA_NOT_FOUND';
  static const String mediaNotReady = 'MEDIA_NOT_READY';
  static const String mediaUploadFailed = 'MEDIA_UPLOAD_FAILED';
  static const String mediaProcessingFailed = 'MEDIA_PROCESSING_FAILED';
  static const String videoServiceUnavailable = 'VIDEO_SERVICE_UNAVAILABLE';
}

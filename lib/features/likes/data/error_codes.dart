/// Backend `errorCode` constants for the Likes and Photo-Exchange
/// domains. Used by data-source classifiers in preference to Arabic
/// message substring matching. Kept as bare strings so they can also
/// be referenced from tests without importing presentation code.
class LikesErrorCodes {
  LikesErrorCodes._();

  static const String subscriptionRequired = 'SUBSCRIPTION_REQUIRED';
  static const String likeNotFound = 'LIKE_NOT_FOUND';
  static const String likeExpired = 'LIKE_EXPIRED';
  static const String likeAlreadyExists = 'LIKE_ALREADY_EXISTS';
  static const String likesQuotaExceeded = 'LIKES_QUOTA_EXCEEDED';
  static const String likesFreeQuotaExceeded = 'LIKES_FREE_QUOTA_EXCEEDED';
  static const String sameGenderNotAllowed = 'SAME_GENDER_NOT_ALLOWED';
  static const String targetUserNotFound = 'TARGET_USER_NOT_FOUND';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String validationError = 'VALIDATION_ERROR';

  /// Profile not yet approved by the matchmaker (server ProfileStatus is
  /// PendingReview). Sending / accepting a like is gated until approval.
  static const String profileNotApproved = 'PROFILE_NOT_APPROVED';
}

class PhotoExchangeErrorCodes {
  PhotoExchangeErrorCodes._();

  static const String likeNotAccepted = 'LIKE_NOT_ACCEPTED';
  static const String photoExchangeNotFound = 'PHOTO_EXCHANGE_NOT_FOUND';
  static const String photoExchangeExpired = 'PHOTO_EXCHANGE_EXPIRED';
  static const String photoExchangeAlreadyPending =
      'PHOTO_EXCHANGE_ALREADY_PENDING';
  static const String photoExchangeLimitReached =
      'PHOTO_EXCHANGE_LIMIT_REACHED';
  static const String photoExchangeFreeLimitReached =
      'PHOTO_EXCHANGE_FREE_LIMIT_REACHED';
  static const String subscriptionRequired = 'SUBSCRIPTION_REQUIRED';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String validationError = 'VALIDATION_ERROR';

  /// Profile not yet approved — requesting a photo exchange is gated
  /// until the matchmaker approves the profile.
  static const String profileNotApproved = 'PROFILE_NOT_APPROVED';
}

/// Backend `errorCode` constants for the formal step — the member-to-member
/// request that precedes the matchmaker's involvement.
///
/// No subscription or limit code here, and that is the contract rather than an
/// omission: the formal step is free where the photo exchange is metered.
///
/// [formalStepNotFound] is deliberately ambiguous on the server side — a
/// member who is not the responder gets it too, so the API never confirms that
/// a request exists to someone who cannot act on it.
class FormalStepErrorCodes {
  FormalStepErrorCodes._();

  static const String formalStepNotFound = 'FORMAL_STEP_NOT_FOUND';
  static const String formalStepExpired = 'FORMAL_STEP_EXPIRED';
  static const String formalStepAlreadyPending = 'FORMAL_STEP_ALREADY_PENDING';
  static const String formalStepNotAllowed = 'FORMAL_STEP_NOT_ALLOWED';

  /// The case was cancelled, failed or completed — nothing is accepted on it.
  static const String caseNotActive = 'CASE_NOT_ACTIVE';

  static const String caseNotFound = 'CASE_NOT_FOUND';
  static const String likeNotAccepted = 'LIKE_NOT_ACCEPTED';
  static const String profileNotApproved = 'PROFILE_NOT_APPROVED';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String validationError = 'VALIDATION_ERROR';
}

/// Backend `errorCode` constants for the Discovery feed. `dailyViewsExceeded`
/// is a "come back tomorrow" cap (with `data.resetAt`) for no-subscription
/// users — NOT a paywall. Consumed by the Discovery feed handling.
class DiscoveryErrorCodes {
  DiscoveryErrorCodes._();

  static const String dailyViewsExceeded = 'DAILY_VIEWS_EXCEEDED';

  /// Profile not yet approved — sending a like is gated until approval.
  static const String profileNotApproved = 'PROFILE_NOT_APPROVED';
}

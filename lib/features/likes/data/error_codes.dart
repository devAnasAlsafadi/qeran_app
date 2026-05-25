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
  static const String sameGenderNotAllowed = 'SAME_GENDER_NOT_ALLOWED';
  static const String targetUserNotFound = 'TARGET_USER_NOT_FOUND';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String validationError = 'VALIDATION_ERROR';
}

class PhotoExchangeErrorCodes {
  PhotoExchangeErrorCodes._();

  static const String likeNotAccepted = 'LIKE_NOT_ACCEPTED';
  static const String photoExchangeNotFound = 'PHOTO_EXCHANGE_NOT_FOUND';
  static const String photoExchangeExpired = 'PHOTO_EXCHANGE_EXPIRED';
  static const String photoExchangeAlreadyPending =
      'PHOTO_EXCHANGE_ALREADY_PENDING';
  static const String subscriptionRequired = 'SUBSCRIPTION_REQUIRED';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String validationError = 'VALIDATION_ERROR';
}

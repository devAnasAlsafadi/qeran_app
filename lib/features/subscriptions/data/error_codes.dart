/// Backend `errorCode` constants for the subscriptions domain. Bare strings so
/// they can be referenced from tests without importing presentation code.
class SubscriptionsErrorCodes {
  SubscriptionsErrorCodes._();

  /// Free trial already consumed — once per user, ever. Treated as a benign
  /// "already done" signal: route the user to a paid plan, not an error screen.
  static const String freePlanAlreadyUsed = 'FREE_PLAN_ALREADY_USED';

  /// Profile not yet approved — subscribe (including free activation) is gated
  /// until the matchmaker approves (ProfileStatus == Visible).
  static const String profileNotApproved = 'PROFILE_NOT_APPROVED';

  /// A gated action needs an active subscription.
  static const String subscriptionRequired = 'SUBSCRIPTION_REQUIRED';

  /// `validate-code` (`03` §12.5): no such code.
  static const String discountCodeInvalid = 'DISCOUNT_CODE_INVALID';

  /// `validate-code`: the code has expired.
  static const String discountCodeExpired = 'DISCOUNT_CODE_EXPIRED';

  /// `validate-code`: the code's GLOBAL cap is reached — never "you already
  /// used it".
  static const String discountCodeExhausted = 'DISCOUNT_CODE_EXHAUSTED';

  /// `validate-code`: configuration on the server's side (product or store
  /// offer not set up) — never the member's fault.
  static const String discountProductUnknown = 'DISCOUNT_PRODUCT_UNKNOWN';
  static const String discountOfferUnavailable = 'DISCOUNT_OFFER_UNAVAILABLE';
}

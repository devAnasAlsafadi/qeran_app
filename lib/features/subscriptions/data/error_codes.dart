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
}

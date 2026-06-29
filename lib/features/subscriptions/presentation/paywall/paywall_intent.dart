/// Why the paywall is being shown. Used by `PaywallBottomSheet` to pick
/// the right headline/body copy without hardcoding strings at call
/// sites.
enum PaywallIntent {
  /// User tried to send a Like — no subscription / limit reached.
  like,

  /// User tried Photo Exchange.
  photoExchange,

  /// User tried to accept an incoming like (future feature surface).
  acceptLike,
}

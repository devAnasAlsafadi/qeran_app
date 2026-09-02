/// The splash's timing, kept out of the widget so it can be tested.
///
/// Three things live here, and they are coupled on purpose:
///
///  * when the reveal counts as finished,
///  * how long the backstop waits before forcing the gate open,
///  * and the dual gate that decides when it is safe to leave.
///
/// They were loose constants in the widget with the coupling between the first
/// two left unenforced — a 3s backstop sitting under a longer asset. Deriving
/// the cap from the asset here means the two can no longer drift apart
/// unnoticed: change [assetDuration] and [safetyCap] follows on its own.
class SplashRevealPolicy {
  const SplashRevealPolicy();

  /// The authored length of the animation we ship.
  ///
  /// Declared rather than discovered because the backstop timer is armed before
  /// the asset has loaded — nothing has asked the asset its length yet. Change
  /// this when the asset changes, and [safetyCap] follows.
  static const Duration assetDuration = Duration(milliseconds: 4333);

  /// Slack between the reveal ending and the backstop firing. Absorbs decode
  /// and first-frame latency on a cold start, which is time the reveal has not
  /// started spending yet.
  static const Duration safetyHeadroom = Duration(seconds: 3);

  /// The backstop: force the animation gate open if nothing else has, so a
  /// stalled or never-loading asset can never hang the splash.
  ///
  /// Always longer than the asset it guards — a backstop that fires first is
  /// not a backstop, it is a truncation.
  Duration get safetyCap => assetDuration + safetyHeadroom;

  /// Whether playback has reached the end of the asset.
  ///
  /// A [total] of zero means the player has not reported a length yet, or
  /// cannot: that is NOT an instant finish, it is an unknown, and answering
  /// `true` there would end the splash on the first frame. The backstop covers
  /// the case where the length never arrives.
  bool hasReachedEnd({required Duration position, required Duration total}) {
    if (total <= Duration.zero) return false;
    return position >= total;
  }

  /// The dual gate: leave only when the animation is done for ANY reason AND
  /// the routing decision has arrived — and never twice.
  ///
  /// Both halves are load-bearing. Dropping [decisionReady] navigates to a
  /// route nobody has chosen yet; dropping [animationSettled] makes the splash
  /// a single frame on the fastest path (an unauthenticated cold start resolves
  /// from two local reads and no network at all).
  bool shouldNavigate({
    required bool animationSettled,
    required bool decisionReady,
    required bool alreadyNavigated,
  }) {
    if (alreadyNavigated) return false;
    return animationSettled && decisionReady;
  }
}

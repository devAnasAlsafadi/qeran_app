/// The splash's timing, kept out of the widget so it can be tested.
///
/// Three things live here, and they are coupled on purpose:
///
///  * how long the reveal plays,
///  * how long the backstop waits before forcing the gate open,
///  * and the dual gate that decides when it is safe to leave.
///
/// They were three loose constants in the widget with the coupling between the
/// first two left unenforced — a 3s backstop sitting under a 3.57s asset. It
/// never actually fired, because a separate 1.8s ceiling squeezed the reveal in
/// under it; removing that ceiling is exactly what would have turned the
/// backstop into a truncation. Deriving the cap from the asset here means the
/// two can no longer drift apart unnoticed.
class SplashRevealPolicy {
  const SplashRevealPolicy();

  /// The authored length of the animation we ship.
  ///
  /// Declared rather than discovered because the backstop timer is armed before
  /// the asset has loaded — nothing has asked the asset its length yet. Change
  /// this when the asset changes, and [safetyCap] follows on its own.
  static const Duration assetDuration = Duration(milliseconds: 3570);

  /// Used only when the asset reports no usable length of its own — a parse
  /// failure, or a composition with a zero duration.
  static const Duration fallbackReveal = Duration(milliseconds: 1800);

  /// Slack between the reveal ending and the backstop firing. Absorbs decode
  /// and first-frame latency on a cold start, which is time the reveal has not
  /// started spending yet.
  static const Duration safetyHeadroom = Duration(seconds: 3);

  /// How long the reveal plays, given whatever the loaded asset reports.
  ///
  /// The reported length is honoured in full. It used to be squeezed into a
  /// 1.8s ceiling — every authored frame preserved, played at roughly twice
  /// speed — which is what "the animation plays too fast" actually was.
  Duration revealFor(Duration reported) =>
      reported.inMicroseconds <= 0 ? fallbackReveal : reported;

  /// The backstop: force the animation gate open if nothing else has, so a
  /// stalled or never-loading asset can never hang the splash.
  ///
  /// Always longer than the reveal it guards — a backstop that fires first is
  /// not a backstop, it is a truncation.
  Duration get safetyCap => assetDuration + safetyHeadroom;

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

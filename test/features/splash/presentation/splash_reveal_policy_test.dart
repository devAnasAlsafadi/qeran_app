import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/splash/presentation/splash_reveal_policy.dart';

void main() {
  const policy = SplashRevealPolicy();

  group('how long the reveal plays', () {
    test('honours the length the asset reports, in full', () {
      const reported = Duration(milliseconds: 3570);

      // The whole point of this sub-step: the reported length used to be
      // squeezed into a 1.8s ceiling and played at roughly twice speed.
      expect(policy.revealFor(reported), reported);
    });

    test('does not shorten an asset longer than the old ceiling', () {
      // 5.23s — the length of the approved animation. Under the retired cap
      // this came out at 1.8s.
      const reported = Duration(milliseconds: 5230);

      expect(policy.revealFor(reported), reported);
    });

    test('a short asset is not stretched either', () {
      const reported = Duration(milliseconds: 400);

      expect(policy.revealFor(reported), reported);
    });

    test('falls back when the asset reports nothing usable', () {
      // Asserted against a LITERAL, not against the constant it returns —
      // comparing `revealFor(zero)` to `fallbackReveal` compares the code with
      // itself and passes for any value, zero included.
      expect(
        policy.revealFor(Duration.zero),
        const Duration(milliseconds: 1800),
      );
    });

    test('the fallback is a real length the ticker can divide by', () {
      // A zero fallback reaches `_startReveal` as `totalUs = 0` and the
      // reveal's elapsed/total becomes NaN — the animation never advances and
      // only the backstop rescues the splash.
      expect(policy.revealFor(Duration.zero), greaterThan(Duration.zero));
    });

    test('falls back on a negative duration rather than running backwards', () {
      expect(
        policy.revealFor(const Duration(seconds: -1)),
        const Duration(milliseconds: 1800),
      );
    });

    test('one microsecond still counts as a real length', () {
      // Pins the boundary at <= 0, not < 0 and not <= some fudge.
      const reported = Duration(microseconds: 1);

      expect(policy.revealFor(reported), reported);
    });
  });

  group('the backstop', () {
    test('outlasts the reveal it guards', () {
      // THE invariant of this sub-step. A 3s backstop over a 3.57s asset is
      // what cut the animation short on every launch, and deriving the cap
      // from the asset is what stops that drifting back.
      expect(
        policy.safetyCap,
        greaterThan(policy.revealFor(SplashRevealPolicy.assetDuration)),
      );
    });

    test('leaves real headroom, not a hair', () {
      // Cold-start decode and first-frame latency are spent before the reveal
      // starts, so the slack has to be worth something.
      expect(
        policy.safetyCap - SplashRevealPolicy.assetDuration,
        SplashRevealPolicy.safetyHeadroom,
      );
      expect(
        SplashRevealPolicy.safetyHeadroom,
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
    });

    test('still outlasts the fallback reveal', () {
      // The other path into the reveal: a broken asset plays the fallback, and
      // the backstop must not cut that short either.
      expect(policy.safetyCap, greaterThan(policy.revealFor(Duration.zero)));
    });
  });

  group('the dual gate', () {
    test('waits for the routing decision even when the animation is done', () {
      expect(
        policy.shouldNavigate(
          animationSettled: true,
          decisionReady: false,
          alreadyNavigated: false,
        ),
        isFalse,
      );
    });

    test('waits for the animation even when the decision has arrived', () {
      // The unauthenticated cold start resolves from two local reads and no
      // network, so without this half the splash would be a single frame.
      expect(
        policy.shouldNavigate(
          animationSettled: false,
          decisionReady: true,
          alreadyNavigated: false,
        ),
        isFalse,
      );
    });

    test('goes once both halves are in', () {
      expect(
        policy.shouldNavigate(
          animationSettled: true,
          decisionReady: true,
          alreadyNavigated: false,
        ),
        isTrue,
      );
    });

    test('never goes twice', () {
      // Both gates satisfied and already gone — a second settle must not push
      // another route onto the stack.
      expect(
        policy.shouldNavigate(
          animationSettled: true,
          decisionReady: true,
          alreadyNavigated: true,
        ),
        isFalse,
      );
    });

    test('stays put when nothing is ready', () {
      expect(
        policy.shouldNavigate(
          animationSettled: false,
          decisionReady: false,
          alreadyNavigated: false,
        ),
        isFalse,
      );
    });
  });
}

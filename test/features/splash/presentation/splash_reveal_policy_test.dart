import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/splash/presentation/splash_reveal_policy.dart';

void main() {
  const policy = SplashRevealPolicy();

  group('when the reveal is over', () {
    test('not until playback reaches the end', () {
      expect(
        policy.hasReachedEnd(
          position: const Duration(seconds: 2),
          total: const Duration(milliseconds: 4333),
        ),
        isFalse,
      );
    });

    test('the moment playback reaches the end', () {
      expect(
        policy.hasReachedEnd(
          position: const Duration(milliseconds: 4333),
          total: const Duration(milliseconds: 4333),
        ),
        isTrue,
      );
    });

    test('a position past the end still counts', () {
      // Player ticks are sampled, so the reported position can land beyond the
      // duration rather than exactly on it.
      expect(
        policy.hasReachedEnd(
          position: const Duration(milliseconds: 4500),
          total: const Duration(milliseconds: 4333),
        ),
        isTrue,
      );
    });

    test('one tick short is still not the end', () {
      // Pins the boundary at >=, not at some rounded-off approximation.
      expect(
        policy.hasReachedEnd(
          position: const Duration(milliseconds: 4332),
          total: const Duration(milliseconds: 4333),
        ),
        isFalse,
      );
    });

    test('an unknown length is not an instant finish', () {
      // THE trap: before the player reports a duration, both values are zero.
      // Answering true here ends the splash on its first frame, which is the
      // single-frame splash the dual gate exists to prevent.
      expect(
        policy.hasReachedEnd(position: Duration.zero, total: Duration.zero),
        isFalse,
      );
    });

    test('a negative length is not an instant finish either', () {
      expect(
        policy.hasReachedEnd(
          position: Duration.zero,
          total: const Duration(seconds: -1),
        ),
        isFalse,
      );
    });

    test('the start of a known asset is not the end of it', () {
      expect(
        policy.hasReachedEnd(
          position: Duration.zero,
          total: const Duration(milliseconds: 4333),
        ),
        isFalse,
      );
    });
  });

  group('the backstop', () {
    test('outlasts the asset it guards', () {
      // A backstop that fires first is not a backstop, it is a truncation.
      expect(policy.safetyCap, greaterThan(SplashRevealPolicy.assetDuration));
    });

    test('is derived from the asset, not written down beside it', () {
      // The coupling is the point: sub-step 3 changed the asset length and the
      // cap had to follow without anyone remembering to edit it.
      expect(
        policy.safetyCap - SplashRevealPolicy.assetDuration,
        SplashRevealPolicy.safetyHeadroom,
      );
    });

    test('leaves real headroom, not a hair', () {
      // Cold-start decode and first-frame latency are spent before playback
      // starts, so the slack has to be worth something.
      expect(
        SplashRevealPolicy.safetyHeadroom,
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
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
      // A tap, the end of playback and the backstop can all settle the same
      // splash; only the first may push a route.
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

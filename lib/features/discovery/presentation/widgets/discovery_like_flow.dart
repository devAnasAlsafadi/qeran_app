import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/like_outcome.dart';
import '../blocs/discovery_cubit.dart';
import 'discovery_deck_animation_controller.dart';

/// Matches `DiscoveryLikeBurst` total duration.
const Duration _kLikeBurstWait = Duration(milliseconds: 480);

/// Let the heart clearly leave the button before the card starts moving.
/// The API already runs in parallel from t=0.
const Duration _kMinimumEjectLead = Duration(milliseconds: 300);

/// Tap-driven Like flow with the API firing at tap time (parallel
/// with the heart burst), the eject conditional on the outcome, and
/// the cubit's emit deferred until the heart finishes:
///
/// ```
/// tap ──┬── spawn heart (480 ms)
///       └── cubit.like(outcomeNotifier, advanceGate)
///                ├── fires API
///                ├── notifies outcomeNotifier when server responds
///                └── awaits advanceGate before emitting state
/// ```
///
/// Once the minimum lead and API outcome are ready, an accepted card ejects
/// while the heart finishes. Paywall / network failures skip the eject so
/// the card stays visible. The cubit gate releases only after both visuals
/// settle.
///
/// [isMounted] ends the sequence early once the action bar is gone;
/// [onSettled] runs when it ends, just before the gate is released.
Future<void> runDiscoveryLikeFlow({
  required DiscoveryCubit cubit,
  required DiscoveryDeckAnimationController controller,
  required bool Function() isMounted,
  required void Function() onSettled,
}) async {
  final outcomeNotifier = Completer<Either<Failure, LikeOutcome>>();
  final advanceGate = Completer<void>();
  // Fire API at tap time. The cubit will await the gate before
  // emitting; it also fires outcomeNotifier the moment the server
  // responds (well before the gate, typically).
  unawaited(
    cubit.like(
      outcomeNotifier: outcomeNotifier,
      advanceGate: advanceGate.future,
    ),
  );
  final heartTimer = Future<void>.delayed(_kLikeBurstWait);
  try {
    await Future<void>.delayed(_kMinimumEjectLead);
    if (!isMounted()) return;
    // No timeout here: the use case already maps transport timeouts to a
    // Failure, and advancing before the server result could remove a card
    // that actually needs to stay (paywall/network).
    final result = await outcomeNotifier.future;
    if (!isMounted()) return;
    final shouldEject = result.fold<bool>(
      (_) => false, // network/unknown — keep the card
      (outcome) => switch (outcome) {
        // Accepted, or "stale" failures where the server already
        // disqualified the card — advance with an eject visual.
        LikeAccepted() => true,
        LikeAlreadyPending() => true,
        LikeGenderMismatch() => true,
        LikeUserUnavailable() => true,
        // Subscription / quota exhausted — paywall slides up, card
        // stays in place.
        LikePaywall() => false,
        // Own profile under review — like is gated; keep the card in place.
        LikeUnderReview() => false,
      },
    );
    if (shouldEject && !controller.isAnimating) {
      // Runs the eject animation. `_runLikeSequence` calls
      // `cubit.like()` at the end — that call no-ops via the cubit's
      // in-flight guard (the original `like()` is still awaiting the
      // gate below), so no duplicate API request fires.
      await controller.triggerLike();
    }
    await heartTimer;
  } finally {
    onSettled();
    // Always release the gate so the cubit's in-flight `like()` can
    // drain its try/finally — leaving the gate open would freeze
    // future Like attempts behind the cubit's `_mutationInFlight`.
    if (!advanceGate.isCompleted) advanceGate.complete();
  }
}

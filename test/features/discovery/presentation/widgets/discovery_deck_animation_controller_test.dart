import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_deck_animation_controller.dart';

void main() {
  group('DiscoveryDeckAnimationController', () {
    late DiscoveryDeckAnimationController c;

    setUp(() => c = DiscoveryDeckAnimationController());
    tearDown(() => c.dispose());

    test('initial state: not animating, no handlers, canLike/Pass false', () {
      expect(c.isAnimating, isFalse);
      expect(c.canLike, isFalse);
      expect(c.canPass, isFalse);
    });

    test('triggerLike with no handler is a no-op', () async {
      await c.triggerLike();
      expect(c.isAnimating, isFalse);
    });

    test('triggerPass with no handler is a no-op', () async {
      await c.triggerPass();
      expect(c.isAnimating, isFalse);
    });

    test('bind exposes canLike + canPass once handlers are present', () {
      c.bind(
        like: () async {},
        pass: () async {},
        snapBack: () async {},
      );
      expect(c.canLike, isTrue);
      expect(c.canPass, isTrue);
    });

    test('triggerLike sets isAnimating, awaits handler, clears it', () async {
      final completer = Completer<void>();
      var handlerStarted = false;

      c.bind(
        like: () async {
          handlerStarted = true;
          await completer.future;
        },
        pass: () async {},
        snapBack: () async {},
      );

      final future = c.triggerLike();
      // Allow the microtask that flips _isAnimating to run.
      await Future<void>.value();

      expect(handlerStarted, isTrue);
      expect(c.isAnimating, isTrue);
      expect(c.canLike, isFalse, reason: 'busy → canLike false');

      completer.complete();
      await future;

      expect(c.isAnimating, isFalse);
      expect(c.canLike, isTrue);
    });

    test('rapid double triggerLike calls handler exactly once', () async {
      var calls = 0;
      final completer = Completer<void>();
      c.bind(
        like: () async {
          calls++;
          await completer.future;
        },
        pass: () async {},
        snapBack: () async {},
      );

      final first = c.triggerLike();
      // Allow the first call to set isAnimating before firing the second.
      await Future<void>.value();
      final second = c.triggerLike(); // should bail immediately

      completer.complete();
      await Future.wait([first, second]);

      expect(calls, 1);
    });

    test(
        'triggerSnapBack runs the bound handler and sets/clears isAnimating',
        () async {
      var calls = 0;
      c.bind(
        like: () async {},
        pass: () async {},
        snapBack: () async {
          calls++;
        },
      );

      await c.triggerSnapBack();
      expect(calls, 1);
      expect(c.isAnimating, isFalse);
    });

    test('triggerSnapBack is a no-op while another animation is in flight',
        () async {
      var snapBackCalls = 0;
      final likeCompleter = Completer<void>();
      c.bind(
        like: () async => likeCompleter.future,
        pass: () async {},
        snapBack: () async {
          snapBackCalls++;
        },
      );

      // Start a Like (holds isAnimating true).
      final like = c.triggerLike();
      await Future<void>.value();
      expect(c.isAnimating, isTrue);

      // Snap-back fired while busy must bail.
      await c.triggerSnapBack();
      expect(snapBackCalls, 0);

      likeCompleter.complete();
      await like;
    });

    test('triggerPass mirrors triggerLike', () async {
      var calls = 0;
      c.bind(
        like: () async {},
        pass: () async {
          calls++;
        },
        snapBack: () async {},
      );

      await c.triggerPass();
      expect(calls, 1);
      expect(c.isAnimating, isFalse);
    });

    test('reset clears isAnimating mid-flight + notifies listeners', () async {
      final completer = Completer<void>();
      c.bind(
        like: () async => completer.future,
        pass: () async {},
        snapBack: () async {},
      );

      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      final future = c.triggerLike();
      await Future<void>.value();
      expect(c.isAnimating, isTrue);
      final beforeReset = notifyCount;

      c.reset();
      expect(c.isAnimating, isFalse);
      expect(notifyCount, greaterThan(beforeReset));

      // The original handler is still pending; completing it must not
      // re-flip isAnimating because the finally-clause guards on the
      // current flag value.
      completer.complete();
      await future;
      expect(c.isAnimating, isFalse);
    });

    test('reset when idle is a no-op (no extra notify)', () {
      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.reset();
      expect(notifyCount, 0);
    });

    test('bind replaces previously-bound handlers', () async {
      var firstCalls = 0;
      var secondCalls = 0;
      c.bind(
        like: () async {
          firstCalls++;
        },
        pass: () async {},
        snapBack: () async {},
      );
      c.bind(
        like: () async {
          secondCalls++;
        },
        pass: () async {},
        snapBack: () async {},
      );

      await c.triggerLike();
      expect(firstCalls, 0);
      expect(secondCalls, 1);
    });

    test('notifyListeners fires on triggerLike start AND completion',
        () async {
      c.bind(
        like: () async {},
        pass: () async {},
        snapBack: () async {},
      );

      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      await c.triggerLike();
      // One for isAnimating = true, one for isAnimating = false.
      expect(notifyCount, 2);
    });
  });

  group('DiscoveryDeckAnimationController — deckProgress', () {
    late DiscoveryDeckAnimationController c;
    setUp(() => c = DiscoveryDeckAnimationController());
    tearDown(() => c.dispose());

    test('initial deckProgress is 0.0', () {
      expect(c.deckProgress.value, 0.0);
    });

    test('deckProgress can be read and written', () {
      c.deckProgress.value = 0.75;
      expect(c.deckProgress.value, 0.75);
    });

    test('deckProgress notifies listeners on change', () {
      var notified = false;
      c.deckProgress.addListener(() => notified = true);
      c.deckProgress.value = 0.5;
      expect(notified, isTrue);
    });

    test('deckProgress is independent of isAnimating flag', () {
      c.deckProgress.value = 0.8;
      expect(c.isAnimating, isFalse,
          reason: 'deckProgress changes do not flip isAnimating');
    });
  });

  group('DiscoveryDeckAnimationController — drag handlers', () {
    late DiscoveryDeckAnimationController c;
    setUp(() => c = DiscoveryDeckAnimationController());
    tearDown(() => c.dispose());

    test('onDragStart/onDragUpdate are no-ops without bindDrag', () {
      c.onDragStart();
      c.onDragUpdate(10);
      // No throw, no busy.
      expect(c.isAnimating, isFalse);
    });

    test('bindDrag exposes start/update/end routing', () async {
      var startCalls = 0;
      final deltas = <double>[];
      var endVelocity = 0.0;
      c.bindDrag(
        onStart: () => startCalls++,
        onUpdate: (dx) => deltas.add(dx),
        onEnd: ({required velocity}) async {
          endVelocity = velocity;
        },
      );

      c.onDragStart();
      c.onDragUpdate(12);
      c.onDragUpdate(8);
      await c.onDragEnd(velocity: 950);

      expect(startCalls, 1);
      expect(deltas, [12, 8]);
      expect(endVelocity, 950);
    });

    test('onDragEnd marks busy for the duration of the handler', () async {
      c.bindDrag(
        onStart: () {},
        onUpdate: (_) {},
        onEnd: ({required velocity}) async {
          // Snapshot busy state from inside the handler.
          expect(c.isAnimating, isTrue);
        },
      );

      expect(c.isAnimating, isFalse);
      await c.onDragEnd(velocity: 0);
      expect(c.isAnimating, isFalse);
    });

    test('onDragStart/Update/End all ignored while isAnimating', () async {
      var startCalls = 0;
      var updateCalls = 0;
      var endCalls = 0;
      c.bind(
        like: () async {
          // Hold isAnimating true while we try drag events.
          c.onDragStart();
          c.onDragUpdate(5);
          await c.onDragEnd(velocity: 100);
        },
        pass: () async {},
        snapBack: () async {},
      );
      c.bindDrag(
        onStart: () => startCalls++,
        onUpdate: (_) => updateCalls++,
        onEnd: ({required velocity}) async {
          endCalls++;
        },
      );

      await c.triggerLike();

      expect(startCalls, 0);
      expect(updateCalls, 0);
      expect(endCalls, 0);
    });

    test('a triggerLike during an in-flight onDragEnd is a no-op', () async {
      var likeCalls = 0;
      c.bind(
        like: () async {
          likeCalls++;
        },
        pass: () async {},
        snapBack: () async {},
      );
      c.bindDrag(
        onStart: () {},
        onUpdate: (_) {},
        onEnd: ({required velocity}) async {
          // Try to fire a button-tap Like while the drag-end handler
          // is still running — should bail.
          await c.triggerLike();
        },
      );

      await c.onDragEnd(velocity: 100);
      expect(likeCalls, 0);
    });
  });

  group('DiscoveryDeckAnimationController — undo', () {
    late DiscoveryDeckAnimationController c;
    setUp(() => c = DiscoveryDeckAnimationController());
    tearDown(() => c.dispose());

    test('initial state: lastExitDirection 0, pendingUndoDirection 0, canUndo true',
        () {
      expect(c.lastExitDirection, 0);
      expect(c.pendingUndoDirection, 0);
      expect(c.canUndo, isTrue);
    });

    test('recordExitDirection accepts +1 / -1 and rejects 0/other', () {
      c.recordExitDirection(1);
      expect(c.lastExitDirection, 1);
      c.recordExitDirection(-1);
      expect(c.lastExitDirection, -1);
      c.recordExitDirection(0);
      expect(c.lastExitDirection, -1, reason: '0 is ignored');
      c.recordExitDirection(5);
      expect(c.lastExitDirection, -1, reason: 'non-±1 is ignored');
    });

    test('triggerUndo sets pendingUndoDirection from last exit + isAnimating',
        () async {
      c.recordExitDirection(1); // last was a Like (right exit)
      late int snapshotPending;
      late bool snapshotAnimating;
      final future = c.triggerUndo(onUndoCall: () {
        snapshotPending = c.pendingUndoDirection;
        snapshotAnimating = c.isAnimating;
        // Simulate the animator's entry animation immediately
        // completing on the next microtask.
        Future<void>.value().then((_) => c.completeUndo());
      });
      await future;

      expect(snapshotPending, 1, reason: 'right exit → return from right');
      expect(snapshotAnimating, isTrue);
      expect(c.pendingUndoDirection, 0);
      expect(c.isAnimating, isFalse);
    });

    test('triggerUndo defaults to -1 when no exit was recorded', () async {
      late int snapshot;
      final future = c.triggerUndo(onUndoCall: () {
        snapshot = c.pendingUndoDirection;
        Future<void>.value().then((_) => c.completeUndo());
      });
      await future;
      expect(snapshot, -1, reason: 'safe default: return from left');
    });

    test('triggerUndo while isAnimating is a no-op', () async {
      c.bind(
        like: () async {
          // Try to fire undo while the Like handler is still running.
          var undoCalled = false;
          await c.triggerUndo(onUndoCall: () => undoCalled = true);
          expect(undoCalled, isFalse);
        },
        pass: () async {},
        snapBack: () async {},
      );

      await c.triggerLike();
    });

    test('reset() skips clearing isAnimating while undo is pending',
        () async {
      c.recordExitDirection(-1);
      final entered = Completer<void>();
      // Start undo but never complete the entry — we want to inspect
      // mid-flight reset behavior.
      // ignore: unawaited_futures
      c.triggerUndo(onUndoCall: () {
        // Simulate the OLD animator's dispose firing reset() right
        // after we kicked off the cubit emit.
        c.reset();
        entered.complete();
      });
      await entered.future;

      // reset() saw pendingUndoDirection != 0 → kept isAnimating true.
      expect(c.isAnimating, isTrue);
      expect(c.pendingUndoDirection, -1);

      // New animator's entry completes — controller clears everything.
      c.completeUndo();
      await Future<void>.value();
      expect(c.isAnimating, isFalse);
      expect(c.pendingUndoDirection, 0);
    });

    test('completeUndo before triggerUndo is a no-op', () {
      // No pending undo → no completer → safe to call.
      c.completeUndo();
      expect(c.isAnimating, isFalse);
    });
  });
}

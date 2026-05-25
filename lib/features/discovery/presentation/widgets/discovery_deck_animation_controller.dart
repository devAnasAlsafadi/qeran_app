import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Shared controller for the Discovery deck's button-driven card
/// animations.
///
/// One instance lives in `_DiscoveryContent` for the lifetime of the
/// screen. The card's animator binds its like/pass sequence-runners on
/// mount; the action bar reads `isAnimating` / `canLike` / `canPass`
/// via the [DeckAnimationScope] inherited notifier and routes
/// button taps through [triggerLike] / [triggerPass].
///
/// The controller does NOT own the `AnimationController` itself — that
/// stays with the `TickerProvider`-backed animator widget. The
/// controller is just the bridge between the action bar (who taps) and
/// the animator (who animates + commits to the cubit).
///
class DiscoveryDeckAnimationController extends ChangeNotifier {
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;

  /// Tracked so a deferred `reset()` post-frame callback doesn't try to
  /// notify after the controller is torn down with the screen.
  bool _disposed = false;

  /// Per-frame swipe / eject progress (0.0 = resting, 1.0 = fully exited).
  /// Updated by [DiscoveryDeckAnimator] on every drag frame and animation
  /// tick. The peek-card layer subscribes via [ValueListenableBuilder] so
  /// only that layer rebuilds — action bar and BlocBuilder are unaffected.
  final ValueNotifier<double> deckProgress = ValueNotifier(0.0);

  @override
  void dispose() {
    deckProgress.dispose();
    _disposed = true;
    super.dispose();
  }

  Future<void> Function()? _likeHandler;
  Future<void> Function()? _passHandler;
  Future<void> Function()? _snapBackHandler;

  /// Drag handlers — owned by the animator. Set via [bindDrag] when the
  /// animator mounts. Live finger updates flow through `onDragStart` /
  /// `onDragUpdate` (no busy flag); `onDragEnd` is the commit point where
  /// the animator decides snap vs eject and the controller marks itself
  /// busy for the duration.
  void Function()? _dragStartHandler;
  void Function(double dx)? _dragUpdateHandler;
  Future<void> Function({required double velocity})? _dragEndHandler;

  /// True when an animator has bound handlers AND no animation is in
  /// flight. Action bar uses this to gate the Like button.
  bool get canLike => !_isAnimating && _likeHandler != null;
  bool get canPass => !_isAnimating && _passHandler != null;

  /// Undo doesn't go through an animator-bound handler — the caller
  /// (action bar) supplies the cubit call to `triggerUndo`, so this
  /// only gates on the busy flag.
  bool get canUndo => !_isAnimating;

  /// Direction of the most recent exit. `+1` = right (Like / swipe
  /// right). `-1` = left (Pass / swipe left). `0` = no exit recorded
  /// yet (cold start). Read by the animator on mount to drive the
  /// undo entry animation.
  int _lastExitDirection = 0;
  int get lastExitDirection => _lastExitDirection;

  /// Non-zero while an undo flow is in flight, BEFORE the new
  /// animator's entry animation has finished. The animator reads this
  /// in `didChangeDependencies` to know which side to slide in from.
  /// Cleared in `triggerUndo`'s finally block.
  int _pendingUndoDirection = 0;
  int get pendingUndoDirection => _pendingUndoDirection;

  /// Completer that resolves when the new animator's entry animation
  /// signals [completeUndo]. Lets `triggerUndo` await the full undo
  /// cycle (cubit emit → new animator mount → entry animation done).
  Completer<void>? _undoCompleter;

  /// Called by the deck animator on mount. The new binding replaces
  /// any previous one. We deliberately do NOT unbind on the animator's
  /// dispose so that the new card's animator can bind cleanly during
  /// the lifecycle crossover (new `didChangeDependencies` runs before
  /// old `dispose` when AnimatedSwitcher swaps children).
  void bind({
    required Future<void> Function() like,
    required Future<void> Function() pass,
    required Future<void> Function() snapBack,
  }) {
    _likeHandler = like;
    _passHandler = pass;
    _snapBackHandler = snapBack;
  }

  /// Binds the animator's drag handlers. Same lifecycle rules as [bind].
  void bindDrag({
    required void Function() onStart,
    required void Function(double dx) onUpdate,
    required Future<void> Function({required double velocity}) onEnd,
  }) {
    _dragStartHandler = onStart;
    _dragUpdateHandler = onUpdate;
    _dragEndHandler = onEnd;
  }

  /// Live finger-down. Ignored while an animation is in flight.
  void onDragStart() {
    if (_isAnimating) return;
    _dragStartHandler?.call();
  }

  /// Incremental drag delta (px). Ignored while an animation is in
  /// flight so a stray gesture event arriving mid-eject doesn't fight
  /// the tween.
  void onDragUpdate(double dx) {
    if (_isAnimating) return;
    _dragUpdateHandler?.call(dx);
  }

  /// Drag release. The animator decides snap-back vs eject. Marks the
  /// controller busy for the whole duration (snap OR eject) so other
  /// gestures and button taps are gated.
  Future<void> onDragEnd({required double velocity}) async {
    if (_isAnimating || _dragEndHandler == null) return;
    _isAnimating = true;
    notifyListeners();
    try {
      await _dragEndHandler!(velocity: velocity);
    } finally {
      if (_isAnimating) {
        _isAnimating = false;
        notifyListeners();
      }
    }
  }

  /// Resets the busy flag. Called by the animator's dispose so an
  /// in-flight `_isAnimating = true` doesn't persist when the deck is
  /// rebuilt externally (e.g. `applyFilters` mid-animation).
  ///
  /// The notification is deferred to a post-frame callback when called
  /// mid-frame (the animator's `dispose()` runs inside the framework's
  /// `lockState` phase, where calling `notifyListeners` would trigger
  /// `markNeedsBuild` on the inherited scope element and assert).
  void reset() {
    // Skip during an undo entry — the new animator owns the
    // isAnimating clear via completeUndo. Resetting here would let
    // the action bar re-enable buttons mid-entry-animation.
    if (_pendingUndoDirection != 0) return;
    if (!_isAnimating) return;
    _isAnimating = false;
    // Pure-unit tests don't initialize a binding — fall through to an
    // immediate notify in that case (safe; there's no frame to fight).
    SchedulerBinding? binding;
    try {
      binding = SchedulerBinding.instance;
    } catch (_) {
      binding = null;
    }
    if (binding == null) {
      notifyListeners();
      return;
    }
    final phase = binding.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      binding.addPostFrameCallback((_) {
        if (_disposed) return;
        notifyListeners();
      });
    }
  }

  Future<void> triggerLike() async {
    if (!canLike) return;
    _isAnimating = true;
    notifyListeners();
    try {
      await _likeHandler!();
    } finally {
      // If reset() was called mid-flight by an external rebuild, the
      // flag is already false — don't double-emit.
      if (_isAnimating) {
        _isAnimating = false;
        notifyListeners();
      }
    }
  }

  Future<void> triggerPass() async {
    if (!canPass) return;
    _isAnimating = true;
    notifyListeners();
    try {
      await _passHandler!();
    } finally {
      if (_isAnimating) {
        _isAnimating = false;
        notifyListeners();
      }
    }
  }

  /// Brings the active card back to centre after a like attempt failed
  /// without an advance — typically a swipe-like that the server
  /// rejected with `LikePaywall` or a network failure. The card has
  /// already animated to its exit position; without this call it would
  /// stay off-screen with no way back. No-op when the card is already
  /// at rest (e.g. a button-driven failure where the eject never ran).
  Future<void> triggerSnapBack() async {
    if (_isAnimating) return;
    final handler = _snapBackHandler;
    if (handler == null) return;
    _isAnimating = true;
    notifyListeners();
    try {
      await handler();
    } finally {
      if (_isAnimating) {
        _isAnimating = false;
        notifyListeners();
      }
    }
  }

  /// Records the direction the just-exited card moved in. Called by
  /// the animator from `_runLikeSequence` / `_runPassSequence` /
  /// `_handleDragEnd` (eject branch) right before it commits to the
  /// cubit. `+1` = right (Like), `-1` = left (Pass).
  void recordExitDirection(int direction) {
    if (direction != -1 && direction != 1) return;
    _lastExitDirection = direction;
  }

  /// Orchestrates an undo:
  ///   1. Pre-set `_pendingUndoDirection` so the new animator (mounted
  ///      by `onUndoCall`'s `cubit.undo()` state change) knows which
  ///      side to slide in from.
  ///   2. Run `onUndoCall` synchronously — the cubit emits a new state,
  ///      AnimatedSwitcher swaps in the new animator.
  ///   3. Wait on `_undoCompleter` — the new animator's entry animation
  ///      calls [completeUndo] when it finishes.
  ///
  /// Unlike `triggerLike` / `triggerPass`, no animator-bound handler
  /// is needed: the action bar already has the cubit and provides
  /// `onUndoCall: cubit.undo`. This also means undo works when the
  /// deck is exhausted (no animator mounted to bind a handler).
  Future<void> triggerUndo({required void Function() onUndoCall}) async {
    if (_isAnimating) return;
    _pendingUndoDirection =
        _lastExitDirection != 0 ? _lastExitDirection : -1;
    _isAnimating = true;
    _undoCompleter = Completer<void>();
    notifyListeners();
    try {
      onUndoCall();
      await _undoCompleter!.future;
    } finally {
      _pendingUndoDirection = 0;
      _undoCompleter = null;
      if (_isAnimating) {
        _isAnimating = false;
        notifyListeners();
      }
    }
  }

  /// Called by the new animator when its undo entry animation finishes.
  /// Resolves the pending [triggerUndo] future. No-op if no undo is in
  /// flight or the completer has already fired.
  void completeUndo() {
    final c = _undoCompleter;
    if (c != null && !c.isCompleted) c.complete();
  }
}

/// `InheritedNotifier` scope exposing the [DiscoveryDeckAnimationController]
/// to both the animator (which binds handlers) and the action bar (which
/// triggers them).
class DeckAnimationScope
    extends InheritedNotifier<DiscoveryDeckAnimationController> {
  const DeckAnimationScope({
    super.key,
    required DiscoveryDeckAnimationController super.notifier,
    required super.child,
  });

  static DiscoveryDeckAnimationController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DeckAnimationScope>();
    assert(scope != null, 'DeckAnimationScope.of called with no scope above.');
    return scope!.notifier!;
  }

  static DiscoveryDeckAnimationController? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DeckAnimationScope>();
    return scope?.notifier;
  }
}

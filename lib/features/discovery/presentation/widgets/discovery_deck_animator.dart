import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/discovery_cubit.dart';
import 'discovery_deck_animation_controller.dart';
import 'discovery_like_overlay.dart';
import 'discovery_pass_overlay.dart';

/// Wraps the active Discovery card and owns the local `AnimationController`
/// that drives all card motion — button-triggered Like/Pass exits,
/// swipe-driven live drag, snap-back, and swipe-eject.
///
/// Single source of truth for the card's horizontal offset
/// ([_dragOffset]). Direct drag updates set it; running animations
/// drive it through a tween. Translate / rotate / opacity / overlays
/// are computed from [_dragOffset] each frame.
///
/// Also owns [DiscoveryDeckAnimationController.deckProgress] updates so
/// the peek-card layer reacts to drag / exit / undo without coupling into
/// this widget's rebuild budget.
class DiscoveryDeckAnimator extends StatefulWidget {
  final Widget child;

  const DiscoveryDeckAnimator({super.key, required this.child});

  @override
  State<DiscoveryDeckAnimator> createState() => _DiscoveryDeckAnimatorState();
}

class _DiscoveryDeckAnimatorState extends State<DiscoveryDeckAnimator>
    with SingleTickerProviderStateMixin {
  static const double _ejectFraction = 0.35;
  static const double _velocityThreshold = 800.0;
  static const double _fullExitFraction = 1.2;

  double _dragOffset = 0;

  late final AnimationController _animator = AnimationController(
    duration: const Duration(milliseconds: 480),
    vsync: this,
  );

  Animation<double>? _offsetAnimation;

  /// Non-null only while a post-exit progress settle is running (new card
  /// mounted, progress tween from the previous exit value back to 0). Checked
  /// by [_onAnimatorTick] to route ticks to `deckProgress` rather than
  /// `_dragOffset`. Nulled by [_cancelSettle] whenever another animation
  /// claims the [_animator].
  Animation<double>? _progressSettleAnimation;

  bool _isUndoEntry = false;

  DiscoveryDeckAnimationController? _scope;

  @override
  void initState() {
    super.initState();
    _animator.addListener(_onAnimatorTick);
  }

  void _onAnimatorTick() {
    if (!mounted) return;
    if (_progressSettleAnimation != null) {
      _scope?.deckProgress.value = _progressSettleAnimation!.value;
      return;
    }
    if (_offsetAnimation == null) return;
    setState(() => _dragOffset = _offsetAnimation!.value);
    _updateDeckProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DeckAnimationScope.of(context);
    if (!identical(next, _scope)) {
      _scope = next;
      _scope!.bind(
        like: _runLikeSequence,
        pass: _runPassSequence,
        snapBack: _snapBackFromExit,
      );
      _scope!.bindDrag(
        onStart: _handleDragStart,
        onUpdate: _handleDragUpdate,
        onEnd: _handleDragEnd,
      );
      // On mount after a Like/Pass exit the controller's deckProgress still
      // holds the exit value (~1.0). Settle it to 0 over 200 ms so the new
      // card feels like it smoothly slides into position rather than the
      // peek card snapping immediately to its resting state.
      if (!_isUndoEntry) {
        final prev = _scope!.deckProgress.value;
        if (prev > 0.01) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _runProgressSettle(prev));
        } else {
          _setDeckProgress(0.0);
        }
      }
      _maybeStartUndoEntry();
    }
  }

  void _maybeStartUndoEntry() {
    final dir = _scope!.pendingUndoDirection;
    if (dir == 0 || _isUndoEntry) return;
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _isUndoEntry = true;
      _dragOffset = dir * width * _fullExitFraction;
    });
    _updateDeckProgress(); // immediately push deckProgress → 1.0
    WidgetsBinding.instance.addPostFrameCallback((_) => _runUndoEntry());
  }

  Future<void> _runUndoEntry() async {
    if (!mounted) return;
    await _animateOffsetTo(
      target: 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _isUndoEntry = false);
    _scope?.completeUndo();
  }

  @override
  void dispose() {
    if (_isUndoEntry) _scope?.completeUndo();
    _scope?.reset();
    // Do NOT write to deckProgress here. Writing to a ValueNotifier during
    // dispose() triggers ValueListenableBuilder.setState while the widget
    // tree is locked (buildOwner.finalizeTree), crashing with
    // "setState called when widget tree was locked".
    // The incoming animator's didChangeDependencies resets the value safely.
    _animator.dispose();
    super.dispose();
  }

  // ── Progress tracking ─────────────────────────────────────────────

  /// Lifecycle-safe write to [deckProgress].
  ///
  /// During [SchedulerPhase.persistentCallbacks] (the build/finalise phase)
  /// a direct write to a [ValueNotifier] triggers
  /// [ValueListenableBuilder.setState] on other elements that are currently
  /// building, causing "setState() called during build". In that phase the
  /// write is deferred to the next post-frame callback. All other scheduler
  /// phases are safe for an immediate write.
  ///
  /// Hot paths that are guaranteed to run outside persistentCallbacks
  /// (e.g. [_onAnimatorTick] during transientCallbacks) may still write
  /// directly for zero overhead.
  void _setDeckProgress(double value) {
    if (!mounted || _scope == null) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scope != null) _scope!.deckProgress.value = value;
      });
    } else {
      _scope!.deckProgress.value = value;
    }
  }

  void _updateDeckProgress() {
    if (_scope == null || !mounted) return;
    if (_progressSettleAnimation != null) return;
    final w = MediaQuery.sizeOf(context).width;
    _setDeckProgress((_dragOffset.abs() / (w * _fullExitFraction)).clamp(0.0, 1.0));
  }

  /// Aborts a running progress-settle so [_animateOffsetTo] can claim the
  /// [_animator] without fighting a stale tween. The settle's `finally`
  /// block will still fire in a microtask but is a no-op because the field
  /// is already null.
  void _cancelSettle() {
    if (_progressSettleAnimation == null) return;
    _progressSettleAnimation = null;
    if (mounted && _scope != null) _setDeckProgress(0.0);
  }

  /// Smoothly reduces `deckProgress` from [from] → 0 over 200 ms. Called
  /// once per new animator mount after a Like/Pass exit so the peek card
  /// settles naturally as the incoming card fades in.
  Future<void> _runProgressSettle(double from) async {
    if (!mounted || _scope == null) return;
    _animator.duration = const Duration(milliseconds: 200);
    _progressSettleAnimation = Tween<double>(begin: from, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_animator);
    try {
      await _animator.forward(from: 0);
    } finally {
      // Null the field; deckProgress was already driven to 0 by the last
      // _onAnimatorTick tick (or by _cancelSettle if interrupted).
      _progressSettleAnimation = null;
    }
  }

  // ── Animations ────────────────────────────────────────────────────

  Future<void> _animateOffsetTo({
    required double target,
    required Duration duration,
    Curve curve = Curves.easeOut,
  }) async {
    _cancelSettle();
    _animator.duration = duration;
    _offsetAnimation = Tween<double>(begin: _dragOffset, end: target)
        .chain(CurveTween(curve: curve))
        .animate(_animator);
    try {
      await _animator.forward(from: 0);
    } finally {
      _offsetAnimation = null;
    }
  }

  // ── Button-triggered exits ─────────────────────────────────────────

  Future<void> _runLikeSequence() async {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width;
    await _animateOffsetTo(
      target: width * _fullExitFraction,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    _scope?.recordExitDirection(1);
    context.read<DiscoveryCubit>().like();
  }

  Future<void> _runPassSequence() async {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width;
    await _animateOffsetTo(
      target: -width * _fullExitFraction,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    _scope?.recordExitDirection(-1);
    context.read<DiscoveryCubit>().pass();
  }

  /// Brings the active card back to its centred resting position from
  /// wherever the drag / eject animation left it. Called by
  /// `DiscoveryDeckAnimationController.triggerSnapBack` when a swipe-
  /// like was rejected by the server (paywall / network) so the card
  /// returns instead of leaving the deck blank. No-op when the offset
  /// is already at rest (button-driven failure path).
  Future<void> _snapBackFromExit() async {
    if (!mounted) return;
    if (_dragOffset.abs() < 0.5) return;
    await _animateOffsetTo(
      target: 0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Drag handlers ──────────────────────────────────────────────────

  void _handleDragStart() {
    _cancelSettle();
  }

  void _handleDragUpdate(double dx) {
    if (!mounted) return;
    _cancelSettle();
    setState(() => _dragOffset += dx);
    _updateDeckProgress();
  }

  Future<void> _handleDragEnd({required double velocity}) async {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width;
    final pastDistance = _dragOffset.abs() > _ejectFraction * width;
    final pastVelocity = velocity.abs() > _velocityThreshold;
    if (!pastDistance && !pastVelocity) {
      await _animateOffsetTo(
        target: 0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final dir = _dragOffset.abs() > 50
        ? (_dragOffset > 0 ? 1 : -1)
        : (velocity > 0 ? 1 : -1);
    final target = dir * width * _fullExitFraction;
    final remaining = (target - _dragOffset).abs() / (width * _fullExitFraction);
    final durationMs = (480 * remaining).clamp(240.0, 480.0).toInt();
    await _animateOffsetTo(
      target: target,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutQuad,
    );
    if (!mounted) return;
    _scope?.recordExitDirection(dir);
    if (dir > 0) {
      context.read<DiscoveryCubit>().like();
    } else {
      context.read<DiscoveryCubit>().pass();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fullExit = width * _fullExitFraction;
    final progress = (_dragOffset.abs() / fullExit).clamp(0.0, 1.0);
    final angle = (_dragOffset / width) * 0.2;
    final cardOpacity = progress <= 0.6
        ? 1.0
        : (1.0 - (progress - 0.6) / 0.4).clamp(0.0, 1.0);

    final cardChild = Transform.translate(
      offset: Offset(_dragOffset, 0),
      child: Transform.rotate(angle: angle, child: widget.child),
    );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (cardOpacity >= 0.99)
          cardChild
        else
          Opacity(
            opacity: cardOpacity,
            child: cardChild,
          ),
        if (_dragOffset > 0 && !_isUndoEntry)
          Positioned.fill(child: DiscoveryLikeOverlay(progress: progress)),
        if (_dragOffset < 0 && !_isUndoEntry)
          Positioned.fill(child: DiscoveryPassOverlay(progress: progress)),
      ],
    );
  }
}

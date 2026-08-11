import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../enum/snakebar_tybe.dart';
import '../widgets/bottom_chrome_inset.dart';
import 'widgets/qeran_snack_bar_widget.dart';

/// Global toast coordinator.
///
/// - Identical visible/pending messages are deduplicated.
/// - Up to three different messages are shown as a vertical stack.
/// - Additional distinct messages wait in a bounded FIFO queue.
/// - One coordinator owns both animation and lifetime, so timers cannot drift
///   away from the visual state.
class AppSnackBar {
  static const Duration _holdDuration = Duration(seconds: 3);
  static const Duration _transitionDuration = Duration(milliseconds: 180);
  static const int _maxVisible = 3;
  static const int _maxPending = 6;

  static final ValueNotifier<List<_SnackMessage>> _visible =
      ValueNotifier<List<_SnackMessage>>(<_SnackMessage>[]);
  static final Queue<_SnackRequest> _pending = Queue<_SnackRequest>();
  static final Map<int, Timer> _holdTimers = <int, Timer>{};
  static final Map<int, Timer> _removalTimers = <int, Timer>{};
  static int _nextId = 0;

  static Future<void> show(
    BuildContext _, {
    required String message,
    required SnackBarType type,
    String? title,
    OverlayState? overlay,
  }) {
    _enqueue(_SnackRequest(message: message, type: type, title: title));
    return Future<void>.value();
  }

  /// Uses the same global host as [show]. Keeping this API means existing
  /// callers that pop a route immediately after showing a toast remain safe.
  static Future<void> showOnRoot({
    required String message,
    required SnackBarType type,
    String? title,
  }) {
    _enqueue(_SnackRequest(message: message, type: type, title: title));
    return Future<void>.value();
  }

  static void _enqueue(_SnackRequest request) {
    final visibleMatch = _visible.value
        .where((item) => item.signature == request.signature)
        .firstOrNull;
    if (visibleMatch != null) {
      _reviveAndRestart(visibleMatch.id);
      return;
    }

    if (_pending.any((item) => item.signature == request.signature)) return;

    if (_visible.value.length < _maxVisible) {
      _activate(request);
      return;
    }

    if (_pending.length >= _maxPending) {
      _pending.removeFirst();
    }
    _pending.addLast(request);
  }

  static void _activate(_SnackRequest request) {
    final item = _SnackMessage(
      id: ++_nextId,
      message: request.message,
      type: request.type,
      title: request.title,
      visible: false,
    );
    _visible.value = <_SnackMessage>[..._visible.value, item];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_contains(item.id)) return;
      _setVisibility(item.id, true);
      _restartHoldTimer(item.id);
    });
  }

  static void _reviveAndRestart(int id) {
    _removalTimers.remove(id)?.cancel();
    _setVisibility(id, true);
    _restartHoldTimer(id);
  }

  static void _restartHoldTimer(int id) {
    _holdTimers.remove(id)?.cancel();
    _holdTimers[id] = Timer(_holdDuration, () => dismiss(id));
  }

  static void dismiss(int id) {
    if (!_contains(id)) return;
    _holdTimers.remove(id)?.cancel();
    _removalTimers.remove(id)?.cancel();
    _setVisibility(id, false);
    _removalTimers[id] = Timer(_transitionDuration, () => _remove(id));
  }

  static void _remove(int id) {
    _holdTimers.remove(id)?.cancel();
    _removalTimers.remove(id)?.cancel();
    _visible.value = _visible.value
        .where((item) => item.id != id)
        .toList(growable: false);
    _promotePending();
  }

  static void _promotePending() {
    while (_visible.value.length < _maxVisible && _pending.isNotEmpty) {
      _activate(_pending.removeFirst());
    }
  }

  static bool _contains(int id) => _visible.value.any((item) => item.id == id);

  static void _setVisibility(int id, bool visible) {
    _visible.value = _visible.value
        .map((item) => item.id == id ? item.copyWith(visible: visible) : item)
        .toList(growable: false);
  }

  @visibleForTesting
  static void debugReset() {
    for (final timer in _holdTimers.values) {
      timer.cancel();
    }
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _holdTimers.clear();
    _removalTimers.clear();
    _pending.clear();
    _visible.value = <_SnackMessage>[];
    _nextId = 0;
  }
}

/// Mount once above the Navigator (see `QeranApp.builder`) so every feature
/// shares the same toast stack across route pushes and pops.
class AppSnackBarHost extends StatelessWidget {
  final Widget child;

  const AppSnackBarHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        // QER-32: bottom, not top. A toast fires in response to a tap, and at
        // the moment of the tap the user's eyes are at the button — near the
        // bottom of the screen — so a top toast lands outside their attention
        // and gets missed. Sits above the safe area so it clears the home
        // indicator / gesture bar.
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          // No SafeArea: the clearance below is already the full band to keep
          // clear, device insets included, so a SafeArea on top would
          // double-count the gesture bar.
          child: ValueListenableBuilder<double>(
            valueListenable: BottomChromeInsets.clearance,
            builder: (context, chrome, _) {
              final media = MediaQuery.of(context);
              return Padding(
                padding: EdgeInsets.only(
                  // Whichever is tallest wins: registered chrome (bottom nav,
                  // discovery action bar), the device's own gesture inset, or
                  // the keyboard. Moving the host to the bottom put it in the
                  // keyboard's path, and validation toasts on the auth screens
                  // fire with the keyboard open.
                  bottom:
                      math.max(
                        chrome,
                        math.max(
                          media.padding.bottom,
                          media.viewInsets.bottom,
                        ),
                      ) +
                      20,
                ),
                child: ValueListenableBuilder<List<_SnackMessage>>(
                  valueListenable: AppSnackBar._visible,
                  builder: (context, messages, _) {
                    return AnimatedSize(
                      duration: AppSnackBar._transitionDuration,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final message in messages)
                            Padding(
                              key: ValueKey<int>(message.id),
                              // Gap ABOVE each card now, so the stack grows upward
                              // from the bottom edge instead of downward from the
                              // top one.
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Semantics(
                                liveRegion: true,
                                child: Material(
                                  color: Colors.transparent,
                                  child: QeranSnackBarWidget(
                                    message: message.message,
                                    title: message.title,
                                    type: message.type,
                                    visible: message.visible,
                                    onDismiss: () =>
                                        AppSnackBar.dismiss(message.id),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

@immutable
class _SnackRequest {
  final String message;
  final SnackBarType type;
  final String? title;

  const _SnackRequest({
    required this.message,
    required this.type,
    required this.title,
  });

  String get signature => '$title|$message|$type';
}

@immutable
class _SnackMessage {
  final int id;
  final String message;
  final SnackBarType type;
  final String? title;
  final bool visible;

  const _SnackMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.title,
    required this.visible,
  });

  String get signature => '$title|$message|$type';

  _SnackMessage copyWith({bool? visible}) {
    return _SnackMessage(
      id: id,
      message: message,
      type: type,
      title: title,
      visible: visible ?? this.visible,
    );
  }
}

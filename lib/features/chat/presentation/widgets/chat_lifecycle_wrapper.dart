import 'dart:async';

import 'package:flutter/widgets.dart';

import '../blocs/conversation_cubit.dart';

/// Wires `WidgetsBindingObserver` to the cubit's
/// `pauseRealtime` / `resumeRealtime` hooks.
///
/// Why a wrapper instead of putting the observer on the cubit: this
/// keeps the cubit free of any Flutter binding dependency, which makes
/// unit-testing the cubit trivial (no need to bootstrap a binding to
/// register observers) AND keeps backgrounding logic in one auditable
/// place — the screen layer.
///
/// Behavior:
///   * `paused`   — start a 60-second grace timer. If the user comes
///                  back inside that window, we keep the connection
///                  open (cheap and avoids needless reconnect storms).
///                  If the timer fires, call `pauseRealtime()`.
///   * `resumed`  — cancel the grace timer; if we already paused,
///                  call `resumeRealtime()` which triggers a page=1
///                  catch-up via the status-transition rule.
///   * `detached` — disconnect immediately; the app is terminating.
///   * `inactive` / `hidden` — no-op (iOS control-center / app-
///                  switcher transitions briefly enter `inactive`;
///                  reacting would cause disconnect storms).
class ChatLifecycleWrapper extends StatefulWidget {
  final ConversationCubit cubit;
  final Widget child;

  /// Grace window before disconnecting on background. Settable for
  /// faster test cycles.
  final Duration backgroundGrace;

  const ChatLifecycleWrapper({
    super.key,
    required this.cubit,
    required this.child,
    this.backgroundGrace = const Duration(seconds: 60),
  });

  @override
  State<ChatLifecycleWrapper> createState() => _ChatLifecycleWrapperState();
}

class _ChatLifecycleWrapperState extends State<ChatLifecycleWrapper>
    with WidgetsBindingObserver {
  Timer? _pauseTimer;
  bool _isCurrentlyPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseTimer?.cancel();
        _pauseTimer = Timer(widget.backgroundGrace, () {
          _isCurrentlyPaused = true;
          unawaited(widget.cubit.pauseRealtime());
        });
      case AppLifecycleState.resumed:
        _pauseTimer?.cancel();
        _pauseTimer = null;
        if (_isCurrentlyPaused) {
          _isCurrentlyPaused = false;
          unawaited(widget.cubit.resumeRealtime());
        }
      case AppLifecycleState.detached:
        _pauseTimer?.cancel();
        _pauseTimer = null;
        _isCurrentlyPaused = true;
        unawaited(widget.cubit.pauseRealtime());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No-op. See class doc — iOS briefly enters `inactive` during
        // routine OS transitions; reacting here would cause needless
        // disconnect/reconnect cycles.
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

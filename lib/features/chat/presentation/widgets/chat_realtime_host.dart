import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/realtime_status.dart';
import '../../domain/ports/chat_realtime_port.dart';

/// Owns the `/hubs/chat` SignalR session for one app shell: opens it on mount,
/// closes it on unmount, and parks it while the app is backgrounded.
///
/// Mounted by the SHELL, not by a chat screen. The hub carries more than one
/// conversation's traffic — `BadgeUpdated` reaches every tab — so the session
/// has to outlive any single screen. A screen-owned session only existed while
/// a conversation was on top, which meant a user who never opened Messages had
/// no socket at all.
///
/// Why a widget rather than logic on a cubit: this keeps the Flutter binding
/// dependency out of the cubits (they stay trivially unit-testable) AND keeps
/// backgrounding rules in one auditable place.
///
/// Behavior:
///   * `paused`   — start a grace timer. Coming back inside the window keeps
///                  the connection open, which avoids reconnect storms on the
///                  brief backgrounding a permission dialog or a share sheet
///                  causes. Only when it fires do we disconnect.
///   * `resumed`  — cancel the timer; reconnect if the grace window elapsed.
///                  `ConversationCubit` watches `statusStream` independently,
///                  so its page=1 catch-up still runs off this reconnect.
///   * `detached` — disconnect at once; the app is terminating.
///   * `inactive` / `hidden` — no-op. iOS enters `inactive` for routine OS
///                  transitions (control centre, app switcher) and reacting
///                  would disconnect on every one of them.
class ChatRealtimeHost extends StatefulWidget {
  const ChatRealtimeHost({
    super.key,
    required this.port,
    required this.accessTokenProvider,
    required this.child,
    this.backgroundGrace = const Duration(seconds: 60),
  });

  final ChatRealtimePort port;

  /// Queried on every connect AND reconnect, so a rotated token is picked up
  /// without touching this widget.
  final ChatAccessTokenProvider accessTokenProvider;

  final Widget child;

  /// Grace window before disconnecting on background. Settable for faster
  /// test cycles.
  final Duration backgroundGrace;

  @override
  State<ChatRealtimeHost> createState() => _ChatRealtimeHostState();
}

class _ChatRealtimeHostState extends State<ChatRealtimeHost>
    with WidgetsBindingObserver {
  Timer? _pauseTimer;
  bool _isCurrentlyPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_safeConnect());
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    // Logout replaces the whole route stack, so this is also the logout
    // teardown: the shell goes, and the socket holding the old token goes
    // with it.
    unawaited(widget.port.disconnect());
    super.dispose();
  }

  /// Connect failures are logged and swallowed. The status stream has already
  /// emitted `disconnected` from the service, REST keeps working, and the next
  /// resume retries — a dead socket must never take the shell down with it.
  Future<void> _safeConnect() async {
    try {
      await widget.port.connect(
        accessTokenProvider: widget.accessTokenProvider,
      );
    } catch (e) {
      AppLogger.warning(
        'CHAT — shell realtime connect failed: $e',
        tag: 'CHAT',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseTimer?.cancel();
        _pauseTimer = Timer(widget.backgroundGrace, () {
          _isCurrentlyPaused = true;
          unawaited(widget.port.disconnect());
        });
      case AppLifecycleState.resumed:
        _pauseTimer?.cancel();
        _pauseTimer = null;
        if (_isCurrentlyPaused) {
          _isCurrentlyPaused = false;
          _reconnect();
        }
      case AppLifecycleState.detached:
        _pauseTimer?.cancel();
        _pauseTimer = null;
        _isCurrentlyPaused = true;
        unawaited(widget.port.disconnect());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Reconnects only from a genuinely dead socket. `connect()` tears down any
  /// live session before opening a new one, so calling it on a healthy
  /// connection is not free — it churns the socket and republishes the whole
  /// status cycle, which downstream reads as a drop and answers with a refetch.
  void _reconnect() {
    if (widget.port.status != RealtimeStatus.disconnected) return;
    unawaited(_safeConnect());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

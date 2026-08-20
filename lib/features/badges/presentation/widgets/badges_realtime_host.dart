import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../chat/domain/entities/badge_update_event.dart';
import '../../../chat/domain/entities/realtime_status.dart';
import '../../../chat/domain/ports/chat_realtime_port.dart';
import '../blocs/badges_cubit.dart';

/// Keeps the badge counts live off the `/hubs/chat` session for one app shell.
///
/// Mounted by the SHELL, inside [ChatRealtimeHost]: that widget owns the
/// connection, this one owns what badges do with it. Two widgets rather than
/// one so the chat feature never has to know badges exist — the dependency runs
/// one way, badges → chat's port.
///
/// Two subscriptions:
///   * `badgeUpdates` — assign the count the server sent. Absolute, never a
///     delta, so a repeat of the same event is harmless. That also makes the
///     matchmaker's two hub connections a non-issue: it holds a second socket
///     for cases, and a duplicate arrival would only assign the same number.
///   * `statusStream` — a socket that dropped and came back missed everything
///     in between, so a return to `connected` refetches. The same rule
///     `ConversationCubit` runs for messages, armed the same way: the FIRST
///     connect refetches nothing, because the shell already fetched on mount.
class BadgesRealtimeHost extends StatefulWidget {
  const BadgesRealtimeHost({
    super.key,
    required this.port,
    required this.badges,
    required this.child,
  });

  final ChatRealtimePort port;
  final BadgesCubit badges;
  final Widget child;

  @override
  State<BadgesRealtimeHost> createState() => _BadgesRealtimeHostState();
}

class _BadgesRealtimeHostState extends State<BadgesRealtimeHost> {
  StreamSubscription<BadgeUpdateEvent>? _updateSub;
  StreamSubscription<RealtimeStatus>? _statusSub;

  /// Armed only once the socket has been up, so the shell's mount fetch and
  /// the first `connected` do not fire two refreshes back to back.
  bool _hasBeenConnected = false;

  @override
  void initState() {
    super.initState();
    _updateSub = widget.port.badgeUpdates.listen(_onUpdate);
    _statusSub = widget.port.statusStream.listen(_onStatus);
    // Seed from the port's CURRENT status. The shell connects before this
    // mounts, and a broadcast stream does not replay, so a spent `connected`
    // would otherwise leave the reconnect rule disarmed for the whole session.
    _onStatus(widget.port.status);
  }

  @override
  void dispose() {
    unawaited(_updateSub?.cancel());
    unawaited(_statusSub?.cancel());
    super.dispose();
  }

  void _onUpdate(BadgeUpdateEvent event) =>
      widget.badges.applyUpdate(event.tab, event.count);

  void _onStatus(RealtimeStatus status) {
    if (status != RealtimeStatus.connected) return;
    if (!_hasBeenConnected) {
      _hasBeenConnected = true;
      return;
    }
    unawaited(widget.badges.refresh());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../badges/presentation/blocs/badges_cubit.dart';
import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';

/// App-wide matchmaker realtime connection (M4c-1). Held by her shell so it
/// stays alive across all tabs, independent of any open chat screen.
/// Matchmaker-only — the user shell is untouched.
class MatchmakerRealtimeHost extends StatefulWidget {
  const MatchmakerRealtimeHost({
    super.key,
    required this.port,
    required this.child,
  });

  final MatchmakerRealtimePort port;
  final Widget child;

  @override
  State<MatchmakerRealtimeHost> createState() => _MatchmakerRealtimeHostState();
}

class _MatchmakerRealtimeHostState extends State<MatchmakerRealtimeHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_safeConnect());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.port.disconnect());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep-alive on pause (no teardown — simplest robust option). On
    // resume, re-establish only if the socket dropped while backgrounded;
    // the cases cubit catches up via its own reconnect listener.
    if (state == AppLifecycleState.resumed) {
      unawaited(sl<BadgesCubit>().refresh());
      if (widget.port.status == MatchmakerRealtimeStatus.disconnected) {
        unawaited(_safeConnect());
      }
    }
  }

  Future<void> _safeConnect() async {
    try {
      await widget.port.connect();
    } catch (_) {
      // The service already emitted `disconnected`; the rest of the shell
      // keeps working and a later resume retries.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/utils/server_clock.dart';

import 'like_countdown_formatter.dart';

/// Compact "waiting" chip showing the remaining time on a pending row.
///
/// Owns its own [Timer.periodic] so the countdown ticks live without a
/// parent rebuild — only this `setState` runs; the timer is cancelled in
/// `dispose`. Tick cadence is 30 s, precise enough for the d/h/m
/// bucketing in [LikeCountdownFormatter] and cheap for a full list.
class LikeCountdownChip extends StatefulWidget {
  final int? initialSeconds;
  final DateTime? expiresAt;

  const LikeCountdownChip({super.key, this.initialSeconds, this.expiresAt})
    : assert(initialSeconds != null || expiresAt != null);

  @override
  State<LikeCountdownChip> createState() => _LikeCountdownChipState();
}

class _LikeCountdownChipState extends State<LikeCountdownChip> {
  static const Duration _tick = Duration(seconds: 30);

  late int _seconds;
  late DateTime _deviceAnchorUtc;
  late DateTime _serverAnchorUtc;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calibrate();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void didUpdateWidget(LikeCountdownChip old) {
    super.didUpdateWidget(old);
    // Cubit refresh emitted a new remaining value — reset the anchor so
    // the next tick subtracts from the fresh baseline, not the stale one.
    if (widget.initialSeconds != old.initialSeconds ||
        widget.expiresAt != old.expiresAt) {
      _calibrate();
      if (_seconds > 0 && !(_timer?.isActive ?? false)) {
        _timer = Timer.periodic(_tick, (_) => _onTick());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final next = _remainingAt(DateTime.now().toUtc());
    if (next == _seconds) return;
    setState(() => _seconds = next);
    // Local countdown hit zero — backend owns the final state; the next
    // refresh moves this row to archived/expired.
    if (next == 0) _timer?.cancel();
  }

  void _calibrate() {
    _deviceAnchorUtc = DateTime.now().toUtc();
    final expiry = widget.expiresAt?.toUtc();
    final snapshot = widget.initialSeconds;

    // `remainingSeconds` is the server's snapshot at response time. Derive
    // the matching server clock once, then advance it by elapsed real time.
    // This keeps `expiresAt` authoritative while avoiding a skewed phone clock.
    if (expiry != null && snapshot != null) {
      _serverAnchorUtc = expiry.subtract(Duration(seconds: snapshot));
      _seconds = snapshot.clamp(0, 1 << 31).toInt();
      return;
    }

    // No snapshot to solve against — the compatibility-case payload sends a
    // deadline alone. Fall back to the process-wide offset learned from the
    // endpoints that DO send both, rather than to the bare device clock: this
    // branch used to be the one place a travelled or drifted clock could put a
    // wrong number on screen.
    _serverAnchorUtc = ServerClock.instance.now();
    _seconds = expiry == null
        ? (snapshot ?? 0).clamp(0, 1 << 31).toInt()
        : _secondsUntil(expiry, _serverAnchorUtc);
  }

  int _remainingAt(DateTime deviceNowUtc) {
    final elapsed = deviceNowUtc.difference(_deviceAnchorUtc);
    final serverNow = _serverAnchorUtc.add(elapsed);
    final expiry = widget.expiresAt?.toUtc();
    if (expiry != null) return _secondsUntil(expiry, serverNow);
    return ((widget.initialSeconds ?? 0) - elapsed.inSeconds)
        .clamp(0, 1 << 31)
        .toInt();
  }

  int _secondsUntil(DateTime expiry, DateTime now) {
    final milliseconds = expiry.difference(now).inMilliseconds;
    if (milliseconds <= 0) return 0;
    // Round up so 1.2 seconds does not display as already expired.
    return (milliseconds / Duration.millisecondsPerSecond).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return QeranChip(
      label: LikeCountdownFormatter.format(context, _seconds),
      variant: QeranChipVariant.status,
      statusColor: QeranColors.goldDeep,
      icon: Icons.access_time_rounded,
      compact: true,
    );
  }
}

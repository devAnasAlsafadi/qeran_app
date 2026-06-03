import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

import 'like_countdown_formatter.dart';

/// Compact "waiting" chip showing the remaining time on a pending row.
///
/// Owns its own [Timer.periodic] so the countdown ticks live without a
/// parent rebuild — only this `setState` runs; the timer is cancelled in
/// `dispose`. Tick cadence is 30 s, precise enough for the d/h/m
/// bucketing in [LikeCountdownFormatter] and cheap for a full list.
class LikeCountdownChip extends StatefulWidget {
  final int initialSeconds;
  const LikeCountdownChip({super.key, required this.initialSeconds});

  @override
  State<LikeCountdownChip> createState() => _LikeCountdownChipState();
}

class _LikeCountdownChipState extends State<LikeCountdownChip> {
  static const Duration _tick = Duration(seconds: 30);

  late int _seconds;
  late DateTime _anchor;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
    _anchor = DateTime.now();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void didUpdateWidget(LikeCountdownChip old) {
    super.didUpdateWidget(old);
    // Cubit refresh emitted a new remaining value — reset the anchor so
    // the next tick subtracts from the fresh baseline, not the stale one.
    if (widget.initialSeconds != old.initialSeconds) {
      _seconds = widget.initialSeconds;
      _anchor = DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final elapsed = DateTime.now().difference(_anchor).inSeconds;
    final next = (widget.initialSeconds - elapsed).clamp(0, 1 << 31);
    if (next == _seconds) return;
    setState(() => _seconds = next);
    // Local countdown hit zero — backend owns the final state; the next
    // refresh moves this row to archived/expired.
    if (next == 0) _timer?.cancel();
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

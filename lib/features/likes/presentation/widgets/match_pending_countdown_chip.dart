import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

import 'like_countdown_formatter.dart';

/// Compact "waiting" chip showing the remaining time on a pending request.
///
/// Deliberately says nothing about WHICH request. It counts down a photo
/// exchange on stage 0 and a formal step on stages 1/2, and it was named for
/// the first of those until the second arrived — a class called
/// `MatchPendingCountdownChip` rendering a formal-step deadline is the kind
/// of name that quietly teaches the next reader something false.
///
/// Owns its own [Timer.periodic] so the countdown ticks live without a
/// parent rebuild; the timer is cancelled in `dispose`. Tick cadence is
/// 30 s — precise enough for the d/h/m bucketing in
/// [LikeCountdownFormatter]. When the local count reaches zero,
/// [onExpired] fires once (the caller refreshes; we don't archive
/// locally).
class MatchPendingCountdownChip extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onExpired;

  const MatchPendingCountdownChip({
    super.key,
    required this.initialSeconds,
    this.onExpired,
  });

  @override
  State<MatchPendingCountdownChip> createState() =>
      _MatchPendingCountdownChipState();
}

class _MatchPendingCountdownChipState
    extends State<MatchPendingCountdownChip> {
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
  void didUpdateWidget(MatchPendingCountdownChip old) {
    super.didUpdateWidget(old);
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
    if (next == 0) {
      _timer?.cancel();
      widget.onExpired?.call();
    }
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

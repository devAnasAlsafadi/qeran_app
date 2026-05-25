import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_text_style.dart';

import 'like_countdown_formatter.dart';

/// Compact chip showing the remaining time on a pending row.
///
/// Owns its own [Timer.periodic] so the countdown ticks live without
/// triggering a parent rebuild — only this `setState` runs. Tick
/// cadence is 30 s, precise enough for d/h/m bucketing and cheap
/// enough that a list of pending rows stays smooth.
///
/// When the local count reaches zero, [onExpired] fires once. The
/// caller typically refreshes matches so the row's server-side state
/// updates. We don't archive locally.
class PhotoExchangeCountdownChip extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onExpired;
  final Color background;
  final Color foreground;

  const PhotoExchangeCountdownChip({
    super.key,
    required this.initialSeconds,
    this.onExpired,
    this.background = const Color(0xFFF6EFE5),
    this.foreground = const Color(0xFFB18454),
  });

  @override
  State<PhotoExchangeCountdownChip> createState() =>
      _PhotoExchangeCountdownChipState();
}

class _PhotoExchangeCountdownChipState
    extends State<PhotoExchangeCountdownChip> {
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
  void didUpdateWidget(PhotoExchangeCountdownChip old) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.foreground.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: widget.foreground),
          const SizedBox(width: 4),
          Text(
            LikeCountdownFormatter.format(context, _seconds),
            style: AppTextStyles.caption.copyWith(
              color: widget.foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

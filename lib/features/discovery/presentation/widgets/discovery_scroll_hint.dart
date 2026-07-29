import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Teaches, once, that the card scrolls.
///
/// The merged screen deliberately ends the first screenful after نبذة عني, so
/// there is nothing peeking above the fold to suggest more exists — the reason
/// the fold reads clean is exactly the reason it hides itself.
///
/// Behaviour follows the usual rules for a coach mark:
/// * it waits for the user to be idle at the top ([_delay]) rather than
///   appearing instantly, so it never competes with the card's own entrance;
/// * it leaves the moment the user scrolls, not after another timer;
/// * and it stops offering itself for good once the gesture has been performed
///   — a hint that keeps reappearing after it has been understood is noise.
///   [dismissed] is owned above the deck, so learning it on one profile
///   settles it for the rest.
///
/// Non-blocking by construction, and it holds no height: it is drawn in the
/// empty paper the fold leaves above the action cluster.
class DiscoveryScrollHint extends StatefulWidget {
  const DiscoveryScrollHint({
    super.key,
    required this.scrollOffset,
    required this.dismissed,
  });

  /// Current card's scroll position. Any real movement retires the hint.
  final ValueListenable<double> scrollOffset;

  /// Latched true once the user has scrolled. Lives above the deck so the hint
  /// teaches once, not once per profile.
  final ValueNotifier<bool> dismissed;

  /// How long the user has to sit still at the top before being offered help.
  static const Duration delay = Duration(milliseconds: 2500);

  /// Scroll distance that counts as "they know how" — past a stray tap wobble.
  static const double learnedAt = 24;

  @override
  State<DiscoveryScrollHint> createState() => _DiscoveryScrollHintState();
}

class _DiscoveryScrollHintState extends State<DiscoveryScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollOffset.addListener(_onScroll);
    widget.dismissed.addListener(_onDismissedChanged);
    _arm();
  }

  @override
  void dispose() {
    widget.scrollOffset.removeListener(_onScroll);
    widget.dismissed.removeListener(_onDismissedChanged);
    _timer?.cancel();
    _bob.dispose();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    if (widget.dismissed.value) return;
    _timer = Timer(DiscoveryScrollHint.delay, () {
      if (!mounted || widget.dismissed.value) return;
      setState(() => _visible = true);
      _bob.repeat(reverse: true);
    });
  }

  void _onScroll() {
    if (widget.scrollOffset.value < DiscoveryScrollHint.learnedAt) return;
    // Understood. Retire it everywhere, for good.
    widget.dismissed.value = true;
  }

  void _onDismissedChanged() {
    if (!widget.dismissed.value) return;
    _timer?.cancel();
    if (!mounted) return;
    _bob.stop();
    if (_visible) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    // Reduced-motion users get the hint without the bob — the message is the
    // point, the movement is only what draws the eye to it.
    final still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        child: Padding(
          padding: const EdgeInsets.only(bottom: QeranSpacing.s8),
          child: AnimatedBuilder(
            animation: _bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, still ? 0 : 4 * _bob.value),
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.discovery_scroll_hint.t(context),
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: QeranColors.wine40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Calm animated affordance that invites first-time Discovery users to
/// swipe the profile upward (revealing the rest of the body). Lifecycle:
///
/// * 400 ms after mount, the pill softly fades in with a tiny upward
///   slide — the travel is intentionally small so the hint reads as a
///   premium whisper rather than a banner drop.
/// * The upward chevron gently bobs **twice** (~1.3 s total) — finite,
///   no infinite loops, `pumpAndSettle`-friendly. Travel is 3 px so the
///   movement feels like a breath, not a bounce.
/// * Once [visible] flips to `false` (parent sets it after the first
///   scroll), the pill fades out smoothly and stays mounted as an
///   invisible `IgnorePointer` so it never blocks touches.
///
/// All controllers / timers are disposed correctly.
class ScrollHint extends StatefulWidget {
  final bool visible;
  const ScrollHint({super.key, required this.visible});

  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint>
    with SingleTickerProviderStateMixin {
  static const Duration _entryDelay = Duration(milliseconds: 400);
  static const Duration _bobHalfCycle = Duration(milliseconds: 460);

  Timer? _entryTimer;
  late final AnimationController _bobCtrl;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(vsync: this, duration: _bobHalfCycle);
    _entryTimer = Timer(_entryDelay, _onEnter);
  }

  Future<void> _onEnter() async {
    if (!mounted) return;
    setState(() => _entered = true);
    // Bob twice (forward → reverse → forward → reverse), then settle.
    for (var i = 0; i < 2; i++) {
      if (!mounted) return;
      await _bobCtrl.forward(from: 0);
      if (!mounted) return;
      await _bobCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showing = _entered && widget.visible;
    return IgnorePointer(
      // Always non-interactive so it can never block scroll or taps.
      child: AnimatedSlide(
        // Small entry offset — pill rises ~18% of its own height, not a
        // full banner drop. Premium "whisper" feel.
        offset: showing ? Offset.zero : const Offset(0, 0.18),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: showing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: _HintPill(bob: _bobCtrl),
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final AnimationController bob;
  const _HintPill({required this.bob});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: AppDimens.p8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14431C33),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: bob,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(bob.value);
                // Travel 3 px upward — matches the "swipe up" cue.
                return Transform.translate(
                  offset: Offset(0, -3 * t),
                  child: child,
                );
              },
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            Text(
              LocaleKeys.discovery_scroll_hint.t(context),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

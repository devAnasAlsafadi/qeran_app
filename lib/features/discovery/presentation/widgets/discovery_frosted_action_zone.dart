import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// Backdrop behind the action cluster ([child]) — a translucent paper strip
/// that fades in only when it is needed.
///
/// [opacity] is 0 at the top of the merged screen, where the buttons float over
/// the empty space below نبذة عني and a card would be pure decoration, and
/// ramps up as profile content scrolls behind them. Even at full strength it
/// stays light: enough separation to keep the glyphs legible, not a solid bar
/// covering what the user is reading.
///
/// Deliberately not a live [BackdropFilter] — the paper tint gives the same
/// separation without re-blurring the content on every scroll frame.
class DiscoveryFrostedActionZone extends StatelessWidget {
  final Widget child;

  /// 0 → fully transparent (no card at all), 1 → the full tint.
  final double opacity;

  const DiscoveryFrostedActionZone({
    super.key,
    required this.child,
    this.opacity = 1,
  });

  /// Peak alpha of the paper fill. Well below the old always-on 0.88, which
  /// read as a solid white bar sitting on top of the profile.
  static const double _maxFill = 0.62;

  @override
  Widget build(BuildContext context) {
    final t = opacity.clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: QeranColors.paper.withValues(alpha: _maxFill * t),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';

/// A compact icon-only secondary action — a round `wine-06` disc with a wine
/// glyph. The matchmaker's tidy secondary affordance beside a gold primary
/// (user cards, and later Cases/Explore/Conversations). While [loading] the
/// glyph becomes an inline loader and taps are suppressed.
class MatchmakerIconAction extends StatelessWidget {
  const MatchmakerIconAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.loading = false,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool loading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyphSize = size * 0.45;
    final button = Material(
      color: QeranColors.wine06,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        splashColor: QeranColors.wine12,
        highlightColor: QeranColors.wine08,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: loading
                ? SizedBox(
                    width: glyphSize,
                    height: glyphSize,
                    child: FittedBox(
                      child: QeranLoader.inline(color: QeranColors.wine),
                    ),
                  )
                : Icon(icon, size: glyphSize, color: QeranColors.wine),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

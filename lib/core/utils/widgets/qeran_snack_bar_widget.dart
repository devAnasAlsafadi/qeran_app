import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../enum/snakebar_tybe.dart';

/// Presentational toast surface used by [AppSnackBar].
///
/// Lifetime, stacking, and visibility are owned by the global coordinator.
class QeranSnackBarWidget extends StatelessWidget {
  final String? title;
  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;
  final bool visible;

  const QeranSnackBarWidget({
    super.key,
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _spec(type);

    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedSlide(
      // Enters from BELOW now that the host is anchored to the bottom edge —
      // a downward-origin slide reads as rising into view rather than the old
      // drop-from-the-top.
      offset: visible ? Offset.zero : const Offset(0, 0.25),
      duration: duration,
      curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: visible ? Curves.easeOut : Curves.easeIn,
        child: Container(
          // QER-32: roomier than the old 16/12 so the card carries weight at
          // the bottom of the screen instead of reading as a thin strip.
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: spec.surface,
            borderRadius: QeranRadii.controlR,
            border: spec.border,
            // Real elevation off a neutral shadow, not a tinted glow derived
            // from the surface. The old shadow was the surface colour at 30%,
            // so on the wine toasts it blended into a wine background instead
            // of separating from it.
            boxShadow: QeranShadows.e3,
          ),
          child: Row(
            children: [
              Icon(spec.icon, color: spec.iconColor, size: 28),
              const SizedBox(width: QeranSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: QeranTypography.title.copyWith(
                          color: spec.foreground,
                        ),
                      ),
                    Text(
                      message,
                      // body (15) rather than caption (12) — the message is
                      // the payload, and at caption size it was the smallest
                      // text on screen.
                      style: QeranTypography.body.copyWith(
                        color: spec.foreground.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: spec.foreground.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Surface + foreground + icon per tone. [error] and [notice] both use a
  /// SOFT surface with a hairline edge and inked-on text — error in the danger
  /// ramp, notice in cream/wine; [success] and [info] sit on dark wine.
  ///
  /// A paper surface was tried for all four when the host moved to the bottom
  /// and it failed: at the bottom the toast lands on the cream canvas, so a
  /// white card on near-white dissolved into the page. Filled wine reads as a
  /// floating layer on every background in the app — cream canvas, white
  /// dome, or the wine hero itself.
  _SnackSpec _spec(SnackBarType type) => switch (type) {
    // Soft danger: a danger-12 fill + danger-40 hairline + danger ink, so a
    // failure reads as clearly ours rather than a full-bleed red banner.
    // The fill is COMPOSITED over paper (like notice's opaque creamSurface)
    // — a translucent surface would let the page bleed through the toast.
    SnackBarType.error => _SnackSpec(
      surface: Color.alphaBlend(QeranColors.danger12, QeranColors.paper),
      foreground: QeranColors.danger,
      iconColor: QeranColors.danger,
      icon: Icons.error_outline_rounded,
      border: Border.all(color: QeranColors.danger40),
    ),
    // Gold check on wine: success is gold in this identity, never green.
    SnackBarType.success => const _SnackSpec(
      surface: QeranColors.wine,
      foreground: QeranColors.paper,
      iconColor: QeranColors.gold,
      icon: Icons.check_circle_rounded,
    ),
    SnackBarType.info => const _SnackSpec(
      surface: QeranColors.wine,
      foreground: QeranColors.paper,
      iconColor: QeranColors.paper,
      icon: Icons.info_outline_rounded,
    ),
    SnackBarType.notice => _SnackSpec(
      surface: QeranColors.creamSurface,
      foreground: QeranColors.wine,
      iconColor: QeranColors.wine,
      icon: Icons.info_outline_rounded,
      border: Border.all(color: QeranColors.hairline),
    ),
  };
}

/// Resolved visual tone for a snackbar.
class _SnackSpec {
  const _SnackSpec({
    required this.surface,
    required this.foreground,
    required this.iconColor,
    required this.icon,
    this.border,
  });

  final Color surface;
  final Color foreground;
  final Color iconColor;
  final IconData icon;
  final BoxBorder? border;
}

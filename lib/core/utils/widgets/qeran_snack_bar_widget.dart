import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
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
      offset: visible ? Offset.zero : const Offset(0, -0.25),
      duration: duration,
      curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: visible ? Curves.easeOut : Curves.easeIn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: spec.surface,
            borderRadius: QeranRadii.controlR,
            border: spec.border,
            boxShadow: [
              BoxShadow(
                color: spec.surface.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(spec.icon, color: spec.iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: QeranTypography.subtitle.copyWith(
                          color: spec.foreground,
                        ),
                      ),
                    Text(
                      message,
                      style: QeranTypography.caption.copyWith(
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
                  size: 18,
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
  _SnackSpec _spec(SnackBarType type) => switch (type) {
    // Soft danger: a danger-12 fill + danger-40 hairline + danger ink, so a
    // failure reads as clearly ours rather than a full-bleed red banner.
    // The fill is COMPOSITED over paper (like notice's opaque creamSurface)
    // — a translucent surface would let the page bleed through the toast and
    // would tint the drop shadow built from it.
    SnackBarType.error => _SnackSpec(
      surface: Color.alphaBlend(QeranColors.danger12, QeranColors.paper),
      foreground: QeranColors.danger,
      iconColor: QeranColors.danger,
      icon: Icons.error_outline_rounded,
      border: Border.all(color: QeranColors.danger40),
    ),
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

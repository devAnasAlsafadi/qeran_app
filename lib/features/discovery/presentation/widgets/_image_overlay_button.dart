import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Circular translucent-dark button used as an overlay on the discovery
/// image (filter button on the leading side, notifications on the
/// trailing side). When `onPressed` is null, the button renders with the
/// same chrome but does not respond to taps — used for the filter
/// placeholder per DISCOVERY_PLAN Q4.
class ImageOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  /// Optional small marker drawn at the top-trailing corner (used by the
  /// notifications bell to indicate unread messages).
  final Widget? badge;

  const ImageOverlayButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.overlayTintDark,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: QeranColors.paper, size: 20),
            ),
            if (badge != null)
              PositionedDirectional(
                top: -2,
                end: -2,
                child: badge!,
              ),
          ],
        ),
      ),
    );
  }
}

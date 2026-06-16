import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/di/injection_container.dart';
import '../enum/snakebar_tybe.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppSnackBar {
  /// Show a snackbar. [overlay] defaults to `Overlay.of(context)`; pass it
  /// explicitly to bind to a specific [OverlayState] (e.g. the root overlay
  /// so the entry survives a route pop).
  static Future<void> show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    String? title,
    OverlayState? overlay,
  }) async {
    final overlayToUse = overlay ?? Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => PositionedDirectional(
        top: MediaQuery.of(context).padding.top + 20,
        start: 20,
        end: 20,
        child: Material(
          color: Colors.transparent,
          child: _SnackBarWidget(
            message: message,
            title: title,
            type: type,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );

    overlayToUse.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  /// Shows a snackbar that survives a route pop (e.g. fired by a listener
  /// about to pop its own screen). Resolves the root navigator's
  /// [OverlayState] via `NavigatorState.overlay` — `navigatorKey.currentContext`
  /// sits ABOVE the Overlay, so `Overlay.of(...)` can't find one upward.
  static Future<void> showOnRoot({
    required String message,
    required SnackBarType type,
    String? title,
  }) async {
    final navState = sl<GlobalKey<NavigatorState>>().currentState;
    final overlayState = navState?.overlay;
    if (overlayState == null) return;
    // The overlay's own context lives inside the overlay subtree (lookups OK).
    return show(
      overlayState.context,
      message: message,
      type: type,
      title: title,
      overlay: overlayState,
    );
  }
}

class _SnackBarWidget extends StatelessWidget {
  final String? title;
  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;

  const _SnackBarWidget({
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Tone per identity (see [_spec]): wine for success/info, danger for
    // error, soft cream for the calm notice channel — never Material red.
    final spec = _spec(type);

    return Container(
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
              Icon(spec.icon, color: spec.iconColor, size: 28)
                  .animate(target: type == SnackBarType.success ? 1 : 0)
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
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
                  Icons.close,
                  color: spec.foreground.withValues(alpha: 0.6),
                  size: 18,
                ),
                onPressed: onDismiss,
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: -1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        ) // Slide down
        .then(delay: 2500.ms) // Wait
        .slideY(begin: 0, end: -1, duration: 400.ms, curve: Curves.easeInBack)
        .shake(); // Slide up to exit
  }

  /// Surface + foreground + icon per tone. [notice] uses a soft cream surface
  /// with wine ink (+ hairline edge); the rest sit on a dark surface.
  _SnackSpec _spec(SnackBarType type) => switch (type) {
        SnackBarType.error => const _SnackSpec(
            surface: QeranColors.danger,
            foreground: QeranColors.paper,
            iconColor: QeranColors.paper,
            icon: Icons.error_outline_rounded,
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

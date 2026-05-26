import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import '../enum/snakebar_tybe.dart';
import '../theme/app_text_style.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppSnackBar {
  /// Show a snackbar. When [overlay] is null we resolve it from
  /// [context] (the historical behavior — every existing caller relies
  /// on this). Pass [overlay] explicitly when you need to bind to a
  /// specific [OverlayState] — e.g. the root navigator's overlay so
  /// the entry survives a route pop.
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

  /// Convenience for showing a snackbar that needs to survive a route
  /// change (e.g. fired by a listener that's about to pop its own
  /// screen). Resolves the root navigator's [OverlayState] directly
  /// via `NavigatorState.overlay` — bypassing the gotcha where
  /// `navigatorKey.currentContext` returns the Navigator's OWN context,
  /// which sits ABOVE the Overlay in the tree, so `Overlay.of(...)`
  /// can never find one upward and throws "No Overlay widget found".
  static Future<void> showOnRoot({
    required String message,
    required SnackBarType type,
    String? title,
  }) async {
    final navState = sl<GlobalKey<NavigatorState>>().currentState;
    final overlayState = navState?.overlay;
    if (overlayState == null) return;
    // Use the overlay's own context — guaranteed to be inside the
    // overlay subtree, so MediaQuery / Localizations lookups inside
    // the entry's builder all resolve correctly.
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
    // Surface tone follows brand identity: success / info both live on
    // wine, with the gold check disambiguating success. Error uses the
    // wine-leaning danger token, never Material red.
    final Color bgColor = type == SnackBarType.error
        ? QeranColors.danger
        : QeranColors.wine;

    final IconData icon = type == SnackBarType.error
        ? Icons.error_outline_rounded
        : (type == SnackBarType.success
              ? Icons.check_circle_rounded
              : Icons.info_outline_rounded);

    // Gold check on wine is the brand's success signal (PDF page 6).
    // Error/info keep a paper icon for legibility on the danger surface.
    final Color iconColor = type == SnackBarType.success
        ? QeranColors.gold
        : QeranColors.paper;

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28)
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: QeranColors.paper,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      message,
                      style: AppTextStyles.caption.copyWith(
                        color: QeranColors.paper.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: QeranColors.paper.withValues(alpha: 0.6),
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
    // .shake(enabled: type == SnackBarType.error); // Shake on error
  }
}

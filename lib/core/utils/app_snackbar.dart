import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import '../enum/snakebar_tybe.dart';
import '../theme/app_text_style.dart';
import 'package:flutter_animate/flutter_animate.dart';
class AppSnackBar {
  static Future<void> show(
      BuildContext context, {
        required String message,
        required SnackBarType type,
        String? title,
      }) async {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
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

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
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
    final Color bgColor = type == SnackBarType.error
        ?  AppColors.error
        : (type == SnackBarType.success ? AppColors.success : Colors.black87);

    final IconData icon = type == SnackBarType.error
        ? Icons.error_outline
        : (type == SnackBarType.success ? Icons.check_circle_outline : Icons.info_outline);

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
          Icon(icon, color: Colors.white, size: 28)
            .animate(target: type == SnackBarType.success ? 1 : 0)
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                 if (title != null)
                   Text(title!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                 Text(message, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    )
    .animate()
    .slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutBack) // Slide down
    .then(delay: 2500.ms) // Wait
    .slideY(begin: 0, end: -1, duration: 400.ms, curve: Curves.easeInBack).shake() ;// Slide up to exit
    // .shake(enabled: type == SnackBarType.error); // Shake on error
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design_system/tokens/qeran_colors.dart';

/// Prevents iOS/app-switcher snapshots from capturing a revealed photo.
/// Android also has FLAG_SECURE at the native window level; this Flutter-side
/// shield gives both platforms an immediate opaque surface while inactive.
class AppLifecyclePrivacyShield extends StatefulWidget {
  final Widget child;

  /// While this reads `true` the shield stays down even when the app leaves the
  /// foreground. `null` (the default) means it never stands down — so a caller
  /// that says nothing keeps the shield it has always had.
  ///
  /// Exists for the splash, which is covered by a fill the same colour as its
  /// own canvas: the screen looks right and the animation is simply gone. See
  /// [privacyShieldSuppressed].
  final ValueListenable<bool>? suppression;

  const AppLifecyclePrivacyShield({
    super.key,
    required this.child,
    this.suppression,
  });

  @override
  State<AppLifecyclePrivacyShield> createState() =>
      _AppLifecyclePrivacyShieldState();
}

class _AppLifecyclePrivacyShieldState extends State<AppLifecyclePrivacyShield>
    with WidgetsBindingObserver {
  bool _concealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final conceal = state != AppLifecycleState.resumed;
    if (conceal != _concealed) setState(() => _concealed = conceal);
  }

  @override
  Widget build(BuildContext context) {
    final suppression = widget.suppression;
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        // `Positioned` has to stay a DIRECT child of the Stack, so the
        // suppression check lives inside the fill rather than around it.
        if (_concealed)
          Positioned.fill(
            child: suppression == null
                ? const ColoredBox(color: QeranColors.wine)
                // Rebuilds on its own when the suppressing screen mounts or
                // leaves, so the app above the shield never has to rebuild.
                : ValueListenableBuilder<bool>(
                    valueListenable: suppression,
                    builder: (context, suppressed, _) => suppressed
                        ? const SizedBox.shrink()
                        : const ColoredBox(color: QeranColors.wine),
                  ),
          ),
      ],
    );
  }
}

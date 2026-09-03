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
    final conceal = _shouldConceal(state);
    if (conceal != _concealed) setState(() => _concealed = conceal);
  }

  /// Android is the ONE platform that does not conceal on `inactive`;
  /// everywhere else keeps the original "anything but resumed" rule.
  ///
  /// `inactive` is transient focus loss with the window STILL VISIBLE — a
  /// permission prompt, the notification shade, the screenshot preview
  /// overlay. On Android that is not an app-switcher moment and the fill just
  /// flashes over content the user is looking at; the recents thumbnail is
  /// already withheld natively by FLAG_SECURE (`MainActivity`), so skipping
  /// `inactive` there costs no protection.
  ///
  /// iOS has no FLAG_SECURE equivalent (QER-3), and its app-switcher gesture
  /// leaves the app inactive-and-visible while it shrinks into its card — so
  /// iOS must keep concealing here. Every other platform keeps the same rule
  /// deliberately: only Android was reasoned about, so nothing else is
  /// narrowed and nothing is left accidentally exposed.
  ///
  /// Reads [defaultTargetPlatform], NOT `dart:io`'s `Platform.isAndroid` that
  /// the rest of the codebase uses. Deliberate: only this one responds to
  /// `TargetPlatformVariant`, and `Platform.isAndroid` is false under
  /// `flutter test` on every host, which would leave this branch permanently
  /// unexercised.
  static bool _shouldConceal(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return false;
    if (state != AppLifecycleState.inactive) return true;
    return defaultTargetPlatform != TargetPlatform.android;
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

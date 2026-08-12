import 'package:flutter/material.dart';

import '../design_system/tokens/qeran_colors.dart';

/// Prevents iOS/app-switcher snapshots from capturing a revealed photo.
/// Android also has FLAG_SECURE at the native window level; this Flutter-side
/// shield gives both platforms an immediate opaque surface while inactive.
class AppLifecyclePrivacyShield extends StatefulWidget {
  final Widget child;

  const AppLifecyclePrivacyShield({super.key, required this.child});

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
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_concealed)
          const Positioned.fill(child: ColoredBox(color: QeranColors.wine)),
      ],
    );
  }
}

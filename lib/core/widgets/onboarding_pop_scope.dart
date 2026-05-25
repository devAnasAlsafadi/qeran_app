import 'package:flutter/material.dart';

import 'package:qeran/core/widgets/exit_app_dialog.dart';

/// Wraps any onboarding [child] with a [PopScope] that intercepts the system
/// back button and shows [ExitAppDialog] instead of allowing a blind pop.
///
/// Use this on every screen where the navigation stack has been cleared
/// (via [pushNamedAndRemoveUntil] or [navigateAndReplace]) so the user
/// can never reach a black screen by pressing back.
class OnboardingPopScope extends StatelessWidget {
  final Widget child;

  const OnboardingPopScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ExitAppDialog.show(context);
        }
      },
      child: child,
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/utils/app_assets.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  /// Spinner on the Google button only — set when Google sign-in is the
  /// action actually running.
  final bool googleLoading;

  /// Spinner on the Apple button only.
  final bool appleLoading;

  /// Any auth action is in flight, including email sign-in. Both buttons go
  /// non-interactive so a second request cannot be fired, but neither shows
  /// a spinner unless it owns the running action.
  final bool busy;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.googleLoading = false,
    this.appleLoading = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          onTap: busy ? null : onGoogleTap,
          loading: googleLoading,
          dimmed: busy,
          child: SvgPicture.asset(AppAssets.googleLogo),
        ),
        if (Platform.isIOS) ...[
          QeranSpacing.hs8,
          _SocialButton(
            onTap: busy ? null : onAppleTap,
            loading: appleLoading,
            dimmed: busy,
            child: const Icon(
              Icons.apple,
              size: 28,
              // Apple HIG requires the Apple mark in true black/white.
              color: QeranColors.appleBlack,
            ),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final bool loading;
  final bool dimmed;

  const _SocialButton({
    required this.onTap,
    required this.child,
    this.loading = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dimmed ? 0.6 : 1.0,
        child: Container(
          // 52 rather than 60 (QER-30): still comfortably above the 48dp
          // minimum tap target, and saves 8px on every auth screen.
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: QeranColors.paper,
            borderRadius: QeranRadii.controlR,
            boxShadow: QeranShadows.e2,
          ),
          // The tile is paper, so the loader keeps its full wine-and-gold
          // dual arc rather than collapsing to one colour.
          child: Center(child: loading ? const QeranLoader(size: 24) : child),
        ),
      ),
    );
  }
}

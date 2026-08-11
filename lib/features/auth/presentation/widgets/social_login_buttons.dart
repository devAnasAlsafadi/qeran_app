import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/utils/app_assets.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  /// When true, replaces button icons with a spinner and disables taps.
  final bool loading;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          onTap: loading ? null : onGoogleTap,
          loading: loading,
          child: SvgPicture.asset(AppAssets.googleLogo),
        ),
        if (Platform.isIOS) ...[
          QeranSpacing.hs8,
          _SocialButton(
            onTap: loading ? null : onAppleTap,
            loading: loading,
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

  const _SocialButton({
    required this.onTap,
    required this.child,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: loading ? 0.6 : 1.0,
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
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: QeranColors.wine,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}


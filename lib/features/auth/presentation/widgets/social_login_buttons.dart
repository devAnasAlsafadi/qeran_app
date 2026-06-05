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

  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          onTap: onGoogleTap,
          child: SvgPicture.asset(AppAssets.googleLogo),
        ),
        if (Platform.isIOS) ...[
          QeranSpacing.hs8,
          _SocialButton(
            onTap: onAppleTap,
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
  final VoidCallback onTap;
  final Widget child;

  const _SocialButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.controlR,
          boxShadow: QeranShadows.e2,
        ),
        child: Center(child: child),
      ),
    );
  }
}

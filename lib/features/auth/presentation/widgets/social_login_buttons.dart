import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/utils/app_dimens.dart';

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
          AppDimens.horizontalSpace8,
          _SocialButton(
            onTap: onAppleTap,
            child: const Icon(Icons.apple, size: 28, color: AppColors.black),
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
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: AppDimens.borderRadius12,
        ),
        child: Center(child: child),
      ),
    );
  }
}

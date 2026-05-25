import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';

/// Shared back button used across auth screens that have a back navigation action.
class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AuthBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

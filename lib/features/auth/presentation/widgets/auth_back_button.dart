import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Shared back button used across auth screens that have a back navigation
/// action. The icon auto-mirrors under the ambient Directionality
/// (matchTextDirection): points right in Arabic/RTL, left in English/LTR.
class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AuthBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: QeranColors.wine,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

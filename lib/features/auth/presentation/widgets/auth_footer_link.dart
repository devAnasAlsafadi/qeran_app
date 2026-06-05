import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// A footer row used across auth screens with a prompt label and a tappable action link.
/// Example: "لا يوجد لديك حساب ؟  [التسجيل]"
class AuthFooterLink extends StatelessWidget {
  final String promptText;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.promptText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          promptText,
          style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
        ),
        const SizedBox(width: QeranSpacing.s4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: QeranTypography.body.copyWith(color: QeranColors.gold),
          ),
        ),
      ],
    );
  }
}

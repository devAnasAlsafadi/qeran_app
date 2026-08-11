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

  /// Wrapped in a `BoxFit.scaleDown` [FittedBox]. As a bare [Row] this
  /// overflowed by 82px at 360dp — the prompt and the gold action link
  /// together are wider than a small phone's dome, so the link was clipped off
  /// the edge and unreachable.
  ///
  /// `scaleDown` rather than a [Wrap]: wrapping to a second line is free on
  /// paper but costs a whole text line, which pushed register back over the
  /// fold on a tall phone (measured 0 → 7px). This keeps the footer exactly
  /// one line tall at every width — untouched when it already fits, gently
  /// scaled when it doesn't — so it can never reintroduce a vertical overflow.
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

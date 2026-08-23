import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';

/// A 52×52 gold circle carrying a single chevron — onboarding's back and next
/// controls. Both directions use it, so the two stay identical in size, colour
/// and lift; only the icon differs.
///
/// Pass a chevron with `matchTextDirection: true` (`arrow_back_ios_rounded` /
/// `arrow_forward_ios_rounded`): it auto-mirrors with the ambient text
/// direction, so never add a manual flip — that would double-flip and cancel
/// the mirroring, per CLAUDE.md rule 4.
class OnboardingCircleButton extends StatelessWidget {
  /// The button's diameter. Also the width the nav row reserves for a hidden
  /// control, so the dots stay centred either way.
  static const double size = 52;

  final IconData icon;
  final VoidCallback onTap;

  const OnboardingCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: QeranColors.gold,
          shape: BoxShape.circle,
          boxShadow: QeranShadows.e3,
        ),
        child: Icon(icon, color: QeranColors.wine, size: 20),
      ),
    );
  }
}

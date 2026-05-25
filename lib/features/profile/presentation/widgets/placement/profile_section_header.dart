import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Wine icon + label. Used by every section of the full profile body
/// so the rendered surface reads as one continuous layout rather than
/// a list of cards.
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: QeranColors.wine),
        QeranSpacing.hs8,
        Flexible(
          child: Text(title, style: QeranTypography.label),
        ),
      ],
    );
  }
}

class ProfileSectionDivider extends StatelessWidget {
  const ProfileSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s20),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: QeranColors.divider),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// One feature line inside a plan card — small burgundy icon, label,
/// and right-aligned value (e.g. "غير محدود" or "50 إعجاب").
class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const FeatureRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: QeranColors.wine),
          const SizedBox(width: QeranSpacing.s8),
          Expanded(
            child: Text(
              label,
              style: QeranTypography.body.copyWith(
                color: QeranColors.inkStrong,
              ),
            ),
          ),
          Text(
            value,
            style: QeranTypography.body.copyWith(
              color: QeranColors.wine,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

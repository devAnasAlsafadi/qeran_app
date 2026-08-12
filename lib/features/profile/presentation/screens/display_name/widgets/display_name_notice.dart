import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Inline notice above the name form — the "you'll be locked for 7 days"
/// warning before an edit, and the "you can edit again in N days" message
/// after one. Same gold treatment as [ProfileGateBanner], which is the app's
/// established language for a non-error advisory; only the icon differs.
class DisplayNameNotice extends StatelessWidget {
  const DisplayNameNotice({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: QeranColors.goldDeep),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              message,
              style: QeranTypography.bodySm.copyWith(
                color: QeranColors.inkBody,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

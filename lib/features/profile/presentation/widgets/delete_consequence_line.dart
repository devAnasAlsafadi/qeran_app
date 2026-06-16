import 'package:flutter/material.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// One "what you lose" line on the delete-account sheet — a small danger dot +
/// muted body text.
class DeleteConsequenceLine extends StatelessWidget {
  const DeleteConsequenceLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: QeranColors.danger),
        ),
        QeranSpacing.hs8,
        Expanded(
          child: Text(
            text,
            style: QeranTypography.body.copyWith(color: QeranColors.inkBody),
          ),
        ),
      ],
    );
  }
}

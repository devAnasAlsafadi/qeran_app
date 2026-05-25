import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// Section header — gold accent bar + title + optional trailing action.
class QeranSectionHeader extends StatelessWidget {
  const QeranSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (accent) ...[
            Container(
              width: 3,
              height: 22,
              decoration: const BoxDecoration(
                color: QeranColors.gold,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            QeranSpacing.hs12,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: QeranTypography.title),
                if (subtitle != null) ...[
                  QeranSpacing.vs4,
                  Text(subtitle!, style: QeranTypography.bodySm),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_button.dart';

/// Brand-aligned empty state. Centered column, cream-disc icon, optional CTA.
class QeranEmptyState extends StatelessWidget {
  const QeranEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.favorite_border_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconDisc(icon: icon),
              QeranSpacing.vs20,
              Text(
                title,
                textAlign: TextAlign.center,
                style: QeranTypography.headline,
              ),
              if (message != null) ...[
                QeranSpacing.vs8,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: QeranTypography.body,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                QeranSpacing.vs24,
                QeranButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: QeranButtonVariant.primary,
                  fullWidth: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: QeranColors.creamSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 36, color: QeranColors.wine),
    );
  }
}

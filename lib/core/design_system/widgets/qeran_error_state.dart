import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_button.dart';

/// Brand-aligned error surface. Same recipe as [QeranEmptyState] but with
/// a wine-leaning icon and an optional retry CTA.
class QeranErrorState extends StatelessWidget {
  const QeranErrorState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

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
              _ErrorDisc(icon: icon),
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
              if (retryLabel != null && onRetry != null) ...[
                QeranSpacing.vs24,
                QeranButton(
                  label: retryLabel!,
                  onPressed: onRetry,
                  variant: QeranButtonVariant.primary,
                  fullWidth: false,
                  leadingIcon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorDisc extends StatelessWidget {
  const _ErrorDisc({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: QeranColors.danger.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, size: 36, color: QeranColors.danger),
      ),
    );
  }
}

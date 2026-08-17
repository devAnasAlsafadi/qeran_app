import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_button.dart';

/// Brand-aligned empty state. Centered column, cream-disc icon, optional CTA
/// plus an optional secondary (ghost) CTA beneath it.
class QeranEmptyState extends StatelessWidget {
  const QeranEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.favorite_border_rounded,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional leading icon on the primary CTA.
  final IconData? actionIcon;

  /// A second, lower-emphasis way out — rendered as a ghost button under the
  /// primary CTA. Added because a filtered empty list needs two exits ("edit
  /// the filter" AND "drop it"), and offering only one turns the other into a
  /// dead end. Both null on every pre-existing call site, so nothing changes
  /// for them.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

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
                  leadingIcon: actionIcon,
                  onPressed: onAction,
                  variant: QeranButtonVariant.primary,
                  fullWidth: false,
                ),
              ],
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                QeranSpacing.vs8,
                QeranButton(
                  label: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  variant: QeranButtonVariant.ghost,
                  size: QeranButtonSize.md,
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

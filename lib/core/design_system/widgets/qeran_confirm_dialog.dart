import 'package:flutter/material.dart';

import '../../../generated/locale_keys.g.dart';
import '../../extensions/localization_extension.dart';
import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// The unified confirm dialog — one identity-styled dialog for every
/// destructive/confirm action app-wide (logout, deactivate, delete, terminal
/// closures…). Icon badge + centred title/message + cancel / confirm buttons.
/// Returns `true` only when the user taps confirm.
///
/// Buttons WRAP their label (no `maxLines`/ellipsis) and equalise height via
/// [IntrinsicHeight], so long Arabic labels never truncate — the bug the old
/// per-feature dialogs had (they reused `QeranButton`, whose text ellipsises at
/// the narrow half-width and rendered "تسجيل خر…").
class QeranConfirmDialog extends StatelessWidget {
  const QeranConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.icon = Icons.warning_amber_rounded,
    this.destructive = true,
  });

  /// All text is pre-resolved by the caller (`LocaleKeys.x.t(context)`).
  final String title;
  final String message;
  final String confirmLabel;

  /// Defaults to the shared "cancel" label when null.
  final String? cancelLabel;
  final IconData icon;

  /// Confirm action tinted danger (true) or wine (false).
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    IconData icon = Icons.warning_amber_rounded,
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => QeranConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = destructive ? QeranColors.danger : QeranColors.wine;
    return Dialog(
      backgroundColor: QeranColors.paper,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s32,
        vertical: QeranSpacing.s24,
      ),
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.cardR),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s24,
          QeranSpacing.s24,
          QeranSpacing.s24,
          QeranSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Badge(icon: icon, color: confirmColor),
            QeranSpacing.vs16,
            Text(title, textAlign: TextAlign.center, style: QeranTypography.title),
            QeranSpacing.vs8,
            Text(
              message,
              textAlign: TextAlign.center,
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
            ),
            QeranSpacing.vs20,
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel ?? LocaleKeys.common_cancel.t(context),
                      color: QeranColors.wine,
                      filled: false,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  QeranSpacing.hs12,
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      color: confirmColor,
                      filled: true,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }
}

/// Dialog action — label WRAPS (no ellipsis) so it never truncates; height is
/// equalised across the row by the parent [IntrinsicHeight].
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : QeranColors.paper,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        borderRadius: QeranRadii.controlR,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s8,
          ),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.controlR,
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: QeranTypography.label.copyWith(
              color: filled ? QeranColors.paper : color,
            ),
          ),
        ),
      ),
    );
  }
}

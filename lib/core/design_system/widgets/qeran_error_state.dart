import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

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

  /// True when [title] or [message] is the offline signal — matched against
  /// both the raw `errors_offline` key and its localized text, so it works
  /// whether the caller passed the key or an already-translated string.
  bool _isOffline(BuildContext context) {
    final key = LocaleKeys.errors_offline;
    final text = key.t(context);
    bool isOfflineStr(String? s) => s != null && (s == key || s == text);
    return isOfflineStr(title) || isOfflineStr(message);
  }

  @override
  Widget build(BuildContext context) {
    // Offline-aware: any failure surfaced here as the offline message (by key
    // or localized text, in either the title or message slot) shows the
    // wifi-off glyph instead of the generic error mark. The offline copy
    // itself flows automatically from `OfflineFailure`'s `errors_offline`.
    final resolvedIcon =
        _isOffline(context) ? Icons.wifi_off_rounded : icon;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ErrorDisc(icon: resolvedIcon),
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

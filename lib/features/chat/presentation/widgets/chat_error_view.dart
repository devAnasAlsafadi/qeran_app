import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Calm full-card error view shown for chat load failures.
/// Defaults to the entry-screen copy; conversation-body failures
/// override [titleKey] to a more specific message.
class ChatErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String titleKey;
  final String retryKey;

  const ChatErrorView({
    super.key,
    required this.onRetry,
    this.titleKey = LocaleKeys.chat_entry_failure_title,
    this.retryKey = LocaleKeys.chat_entry_retry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: QeranColors.inkMuted,
            ),
            const SizedBox(height: QeranSpacing.s12),
            Text(
              titleKey.t(context),
              textAlign: TextAlign.center,
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
            ),
            const SizedBox(height: QeranSpacing.s16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryKey.t(context),
                style: QeranTypography.label.copyWith(color: QeranColors.wine),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

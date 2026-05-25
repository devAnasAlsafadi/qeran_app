import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppDimens.p12),
            Text(
              titleKey.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryKey.t(context),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

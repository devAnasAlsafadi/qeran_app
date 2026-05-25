import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Compact error state with a retry button. Used whenever the
/// incoming / outgoing fetch returns `Left(Failure)`.
///
/// Raw backend strings are intentionally NOT rendered here — the
/// `ServerFailure.message` we receive may be a raw English token like
/// `"Operation Failed"` (or any future server-side variant), and
/// passing those through `.tr()` would log a missing-key warning AND
/// surface unlocalized text to the user. The view falls back to the
/// generic `errors.generic` description so the experience stays
/// premium across both languages. The raw message is logged at the
/// cubit / repository layer for engineering follow-up.
class LikesErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const LikesErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p32),
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
              LocaleKeys.likes_error_title.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              LocaleKeys.errors_generic.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                LocaleKeys.likes_error_retry.t(context),
                style: AppTextStyles.bodyMedium.copyWith(
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

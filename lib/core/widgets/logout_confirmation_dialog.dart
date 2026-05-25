import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Premium logout confirmation dialog matching the Qeran luxury identity:
/// burgundy accents, warm beige surface, soft shadow, rounded corners,
/// and a subtle fade + scale entrance. Returns `true` only when the user
/// taps the confirm action.
class LogoutConfirmationDialog {
  const LogoutConfirmationDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: LocaleKeys.dialogs_logout_title.t(context),
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: const _LogoutDialogCard(),
          ),
        );
      },
    );
    return result ?? false;
  }
}

class _LogoutDialogCard extends StatelessWidget {
  const _LogoutDialogCard();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29431C33),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LogoutBadge(),
            const SizedBox(height: 18),
            Text(
              LocaleKeys.dialogs_logout_title.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.dialogs_logout_message.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _DialogActionButton(
                    label: LocaleKeys.common_cancel.t(context),
                    filled: false,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogActionButton(
                    label: LocaleKeys.common_logout.t(context),
                    filled: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutBadge extends StatelessWidget {
  const _LogoutBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.10),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.logout_rounded,
        size: 30,
        color: AppColors.primary,
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const _DialogActionButton({
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : AppColors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: filled ? AppColors.white : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

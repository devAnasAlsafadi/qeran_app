import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';

/// Platform-adaptive exit/logout dialog shown when the user presses the
/// system back button during onboarding screens where the navigation stack
/// has been cleared.
///
/// - **Android:** Offers to exit the app via [SystemNavigator.pop].
/// - **iOS:** Offers to log out and return to the login screen, since Apple
///   guidelines forbid programmatic app termination.
class ExitAppDialog {
  const ExitAppDialog._();

  static Future<void> show(BuildContext context) async {
    if (Platform.isIOS) {
      await _showIosLogoutDialog(context);
    } else {
      await _showAndroidExitDialog(context);
    }
  }

  // ─── Android: Exit App ────────────────────────────────────────

  static Future<void> _showAndroidExitDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocaleKeys.dialogs_exit_app_title.t(ctx),
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          LocaleKeys.dialogs_exit_app_message.t(ctx),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocaleKeys.common_cancel.t(ctx),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: Text(
              LocaleKeys.common_exit.t(ctx),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── iOS: Log out ─────────────────────────────────────────────

  static Future<void> _showIosLogoutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocaleKeys.dialogs_logout_title.t(ctx),
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          LocaleKeys.dialogs_logout_message.t(ctx),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocaleKeys.common_cancel.t(ctx),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await sl<StorageService>().remove(StorageKeys.token);
              await sl<SharedPrefService>().remove(StorageKeys.pendingUserId);
              if (context.mounted) {
                NavigationManager.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.loginScreen,
                );
              }
            },
            child: Text(
              LocaleKeys.common_logout.t(ctx),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

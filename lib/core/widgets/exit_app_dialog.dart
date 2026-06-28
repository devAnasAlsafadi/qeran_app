import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/services/storage_service.dart';

/// Platform-adaptive exit/logout helper shown when the user presses the
/// system back button during onboarding screens where the navigation stack
/// has been cleared. Styling is delegated to [QeranConfirmDialog]; this thin
/// wrapper owns only the platform branch + the terminal side effects.
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

  static Future<void> _showAndroidExitDialog(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.dialogs_exit_app_title.t(context),
      message: LocaleKeys.dialogs_exit_app_message.t(context),
      confirmLabel: LocaleKeys.common_exit.t(context),
      icon: Icons.exit_to_app_rounded,
    );
    if (confirmed) SystemNavigator.pop();
  }

  // ─── iOS: Log out ─────────────────────────────────────────────

  static Future<void> _showIosLogoutDialog(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.dialogs_logout_title.t(context),
      message: LocaleKeys.dialogs_logout_message.t(context),
      confirmLabel: LocaleKeys.common_logout.t(context),
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    await sl<StorageService>().remove(StorageKeys.token);
    await sl<SharedPrefService>().remove(StorageKeys.pendingUserId);
    if (context.mounted) {
      NavigationManager.pushNamedAndRemoveUntil(
        context,
        RouteNames.loginScreen,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../widgets/subscription_status_block.dart';

/// Dedicated host for the existing `SubscriptionStatusBlock`. Settings
/// no longer embeds the bulky status card inline — instead a single
/// `اشتراكي` row taps through here so the settings list stays a clean
/// column of options.
///
/// No new business state: `SubscriptionStatusBlock` already reads from
/// the app-scoped `CurrentSubscriptionCubit` and renders all four
/// emotional variants (loading / loaded-active / loaded-expired / none).
///
/// TODO(phase4-bg-unification): Scaffold background is intentionally
/// `AppColors.background` (white) for visual parity with the Settings
/// tab, which renders inside `HomeScreen`'s Scaffold and that screen
/// explicitly overrides `QeranTheme`'s cream canvas with the same
/// white. When the Phase 4 background unification milestone lands,
/// flip both `HomeScreen` and this screen to inherit the theme's
/// `QeranColors.creamCanvas` default (just remove the override here
/// and on `home_screen.dart:40`).
class SubscriptionDetailsScreen extends StatelessWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QeranAppBar(
        title: LocaleKeys.subscriptions_status_my_subscription.t(context),
        background: AppColors.background,
      ),
      body: const SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SubscriptionStatusBlock(),
        ),
      ),
    );
  }
}

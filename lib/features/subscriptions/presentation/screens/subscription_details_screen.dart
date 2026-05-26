import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
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
/// Scaffold + app bar inherit `QeranTheme`'s cream-canvas defaults per
/// BRAND_DECISION.md — no explicit override needed.
class SubscriptionDetailsScreen extends StatelessWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QeranAppBar(
        title: LocaleKeys.subscriptions_status_my_subscription.t(context),
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

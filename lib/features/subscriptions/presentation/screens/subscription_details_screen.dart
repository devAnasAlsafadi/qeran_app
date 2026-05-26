import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
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
class SubscriptionDetailsScreen extends StatelessWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.subscriptions_status_my_subscription.t(context),
      ),
      body: const SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          // Wider margins than the settings list — the subscription
          // status card is tall, so a 16 dp gutter makes the cream
          // canvas read as a thin border. 20 h × 24 t × 32 b gives the
          // cream visible presence around the paper card.
          padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: SubscriptionStatusBlock(),
        ),
      ),
    );
  }
}

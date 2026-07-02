import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_premium_banner.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Paywall hero — the wine-deep premium banner shown to non-subscribers.
class PaywallHeroWidget extends StatelessWidget {
  const PaywallHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return QeranPremiumBanner(
      title:
          LocaleKeys.subscriptions_status_not_subscribed_title.t(context),
      subtitle:
          LocaleKeys.subscriptions_status_not_subscribed_body.t(context),
    );
  }
}

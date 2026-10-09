import 'package:qeran/generated/locale_keys.g.dart';

import 'paywall_intent.dart';

/// The paywall sheet's title and body keys, per intent. A like with an
/// active subscription means the allowance is used up, not missing.
class PaywallCopy {
  final String title;
  final String body;
  const PaywallCopy({required this.title, required this.body});

  static PaywallCopy of(PaywallIntent intent, {required bool hasActive}) =>
      switch (intent) {
        PaywallIntent.like =>
          hasActive
              ? const PaywallCopy(
                  title: LocaleKeys.subscriptions_paywall_likes_exhausted_title,
                  body: LocaleKeys.subscriptions_paywall_likes_exhausted_body,
                )
              : const PaywallCopy(
                  title: LocaleKeys.subscriptions_paywall_like_title,
                  body: LocaleKeys.subscriptions_paywall_like_body,
                ),
        PaywallIntent.photoExchange => const PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_photo_title,
          body: LocaleKeys.subscriptions_paywall_photo_body,
        ),
        PaywallIntent.acceptLike => const PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_accept_title,
          body: LocaleKeys.subscriptions_paywall_accept_body,
        ),
      };
}

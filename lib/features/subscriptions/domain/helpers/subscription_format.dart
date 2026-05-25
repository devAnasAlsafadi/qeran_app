import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../entities/current_subscription.dart';
import '../entities/subscription_features.dart';

/// Plain helpers for rendering the `-1` (features) and `int.MaxValue`
/// (remaining counters) sentinels as "غير محدود". UI must use these
/// instead of inline magic-number checks.
class SubscriptionFormat {
  const SubscriptionFormat._();

  /// `-1` → "غير محدود", else "$value $unit".
  static String formatAllowed(BuildContext context, int value, String unit) {
    if (SubscriptionFeatures.isUnlimited(value)) {
      return LocaleKeys.subscriptions_unlimited.t(context);
    }
    return '$value $unit';
  }

  /// `int.MaxValue` → "غير محدود", else "$value".
  static String formatRemaining(BuildContext context, int value) {
    if (CurrentSubscription.isUnlimitedRemaining(value)) {
      return LocaleKeys.subscriptions_unlimited.t(context);
    }
    return '$value';
  }

  /// Used / total ratio in `[0, 1]`. Returns 0 for unlimited or zero
  /// totals so progress bars stay empty rather than crashing.
  static double usagePercent(int used, int total) {
    if (CurrentSubscription.isUnlimitedRemaining(total) || total <= 0) {
      return 0;
    }
    return (used / total).clamp(0.0, 1.0);
  }
}

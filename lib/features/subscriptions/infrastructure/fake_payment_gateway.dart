import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/services/payment_gateway.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../domain/entities/subscription_pricing.dart';

/// Development-only payment stub. Shows a dialog that lets the tester
/// choose between simulated "success" and "cancel" so the rest of the
/// subscription flow can be exercised end-to-end before a real gateway
/// is wired. **Never ship this to production.**
///
/// Uses the app-wide [GlobalKey] attached to `MaterialApp.navigatorKey`
/// — always fresh, no `initState`/`dispose` lifecycle hooks required.
/// To swap in a real gateway later, replace the binding in
/// `subscriptions_injection.dart`; nothing else changes.
class FakePaymentGateway implements PaymentGateway {
  final GlobalKey<NavigatorState> _navigatorKey;

  FakePaymentGateway({required GlobalKey<NavigatorState> navigatorKey})
      : _navigatorKey = navigatorKey;

  @override
  Future<PaymentResult> payForPricing({
    required SubscriptionPricing pricing,
    required double finalAmount,
    String? discountCode,
  }) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      // Dev environment with no live navigator (e.g. widget tests). Fail
      // explicitly so the cubit short-circuits to its Failure branch
      // instead of incorrectly continuing to /subscribe.
      return const PaymentResult.failed(
        message: 'No navigator bound to the app — cannot show fake payment.',
      );
    }

    final result = await showDialog<PaymentResultStatus>(
      context: navigator.context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => _FakePaymentDialog(amount: finalAmount),
    );

    // Yield a frame so the dialog has fully unmounted before the
    // caller emits new state — avoids a transient layout glitch on
    // some devices.
    await SchedulerBinding.instance.endOfFrame;

    return switch (result) {
      PaymentResultStatus.success =>
        const PaymentResult.success(gatewayRef: 'fake-success'),
      PaymentResultStatus.cancelled || null =>
        const PaymentResult.cancelled(),
      PaymentResultStatus.failed =>
        const PaymentResult.failed(message: 'Simulated failure'),
    };
  }
}

class _FakePaymentDialog extends StatelessWidget {
  final double amount;
  const _FakePaymentDialog({required this.amount});

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p24,
          AppDimens.p24,
          AppDimens.p24,
          AppDimens.p20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.payments_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              LocaleKeys.subscriptions_fake_payment_title.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppDimens.p8),
            Text(
              LocaleKeys.subscriptions_fake_payment_message.t(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              '${amount.toStringAsFixed(2)} $currency',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppDimens.p20),
            CustomButton(
              text: LocaleKeys.subscriptions_fake_payment_confirm.t(context),
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.of(context)
                  .pop(PaymentResultStatus.success),
            ),
            const SizedBox(height: AppDimens.p8),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(PaymentResultStatus.cancelled),
              child: Text(
                LocaleKeys.subscriptions_fake_payment_cancel.t(context),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

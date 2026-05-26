import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/services/payment_gateway.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../domain/entities/subscription_pricing.dart';

/// Development-only payment stub. Shows a brand-aligned dialog that
/// auto-progresses through a 2 s "processing" state, then reveals a
/// success screen the tester confirms to continue. A subtle cancel
/// affordance remains so simulated failures stay reachable. **Never
/// ship this to production.**
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

class _FakePaymentDialog extends StatefulWidget {
  final double amount;
  const _FakePaymentDialog({required this.amount});

  @override
  State<_FakePaymentDialog> createState() => _FakePaymentDialogState();
}

enum _DialogPhase { processing, success }

class _FakePaymentDialogState extends State<_FakePaymentDialog> {
  _DialogPhase _phase = _DialogPhase.processing;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _phase = _DialogPhase.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: QeranColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s24,
          QeranSpacing.s24,
          QeranSpacing.s24,
          QeranSpacing.s20,
        ),
        child: _phase == _DialogPhase.processing
            ? _ProcessingBody(amount: widget.amount)
            : _SuccessBody(
                onContinue: () => Navigator.of(context)
                    .pop(PaymentResultStatus.success),
                onCancel: () => Navigator.of(context)
                    .pop(PaymentResultStatus.cancelled),
              ),
      ),
    );
  }
}

class _ProcessingBody extends StatelessWidget {
  final double amount;
  const _ProcessingBody({required this.amount});

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const QeranLoader(size: 56),
        const SizedBox(height: QeranSpacing.s20),
        Text(
          'جارٍ معالجة الدفع...',
          textAlign: TextAlign.center,
          style: QeranTypography.title.copyWith(color: QeranColors.wine),
        ),
        const SizedBox(height: QeranSpacing.s8),
        Text(
          '${amount.toStringAsFixed(2)} $currency',
          textAlign: TextAlign.center,
          style: QeranTypography.numeric.copyWith(
            color: QeranColors.inkMuted,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onCancel;
  const _SuccessBody({required this.onContinue, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: QeranColors.gold12,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: QeranColors.gold,
            size: 64,
          ),
        ),
        const SizedBox(height: QeranSpacing.s20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'تم الاشتراك بنجاح',
              style: QeranTypography.title.copyWith(color: QeranColors.wine),
            ),
            const SizedBox(width: QeranSpacing.s8),
            const Icon(
              Icons.celebration_rounded,
              color: QeranColors.gold,
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: QeranSpacing.s8),
        Text(
          'أهلاً بك. استمتع بمزايا اشتراكك الجديد.',
          textAlign: TextAlign.center,
          style: QeranTypography.body.copyWith(color: QeranColors.inkBody),
        ),
        const SizedBox(height: QeranSpacing.s24),
        QeranButton(
          label: 'ابدأ الآن',
          onPressed: onContinue,
        ),
        const SizedBox(height: QeranSpacing.s8),
        QeranButton(
          label: LocaleKeys.subscriptions_fake_payment_cancel.t(context),
          variant: QeranButtonVariant.ghost,
          size: QeranButtonSize.md,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

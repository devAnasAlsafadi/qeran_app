import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Stateful visual-only payment selector. Default selection is "card"
/// (Visa/Mastercard). Selection has no behavioural effect today — every
/// method routes to the same gateway downstream.
///
// TODO(payments): wire each payment method to its real gateway once
// backend support is added. Today this is purely a visual surface.
class CheckoutPaymentMethods extends StatefulWidget {
  const CheckoutPaymentMethods({super.key});

  @override
  State<CheckoutPaymentMethods> createState() => _CheckoutPaymentMethodsState();
}

enum _PaymentMethod { card, mada, applePay }

class _CheckoutPaymentMethodsState extends State<CheckoutPaymentMethods> {
  _PaymentMethod _selected = _PaymentMethod.card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.subscriptions_payment_method.t(context),
          style: QeranTypography.subtitle.copyWith(color: QeranColors.wine),
        ),
        const SizedBox(height: QeranSpacing.s12),
        _MethodTile(
          icon: Icons.credit_card_rounded,
          label: LocaleKeys.subscriptions_payment_card.t(context),
          subtitle: 'Visa, Mastercard',
          selected: _selected == _PaymentMethod.card,
          onTap: () => setState(() => _selected = _PaymentMethod.card),
        ),
        const SizedBox(height: QeranSpacing.s8),
        _MethodTile(
          icon: Icons.account_balance_rounded,
          label: LocaleKeys.subscriptions_payment_mada.t(context),
          subtitle: LocaleKeys.subscriptions_payment_mada_subtitle.t(context),
          selected: _selected == _PaymentMethod.mada,
          onTap: () => setState(() => _selected = _PaymentMethod.mada),
        ),
        const SizedBox(height: QeranSpacing.s8),
        _MethodTile(
          icon: Icons.apple,
          label: 'Apple Pay',
          subtitle: LocaleKeys.subscriptions_payment_apple_subtitle.t(context),
          selected: _selected == _PaymentMethod.applePay,
          onTap: () => setState(() => _selected = _PaymentMethod.applePay),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      borderRadius: QeranRadii.cardR,
      child: InkWell(
        borderRadius: QeranRadii.cardR,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(QeranSpacing.s16),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.cardR,
            boxShadow: QeranShadows.e2,
            border: Border.all(
              color: selected ? QeranColors.gold : QeranColors.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Radio(selected: selected),
              const SizedBox(width: QeranSpacing.s12),
              Icon(icon, color: QeranColors.wine, size: 22),
              const SizedBox(width: QeranSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: QeranTypography.subtitle.copyWith(
                        color: QeranColors.wine,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: QeranTypography.caption.copyWith(
                        color: QeranColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QeranColors.gold : QeranColors.wine40,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.gold,
              ),
            )
          : null,
    );
  }
}

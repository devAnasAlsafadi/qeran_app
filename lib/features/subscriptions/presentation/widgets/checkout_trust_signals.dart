import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Three equal-width trust badges below the payment selector —
/// reassures the user right before the confirm CTA.
class CheckoutTrustSignals extends StatelessWidget {
  const CheckoutTrustSignals({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.cardR,
      ),
      child: const Row(
        children: [
          Expanded(
            child: _Badge(
              icon: Icons.security_rounded,
              label: 'دفع آمن مشفر',
            ),
          ),
          Expanded(
            child: _Badge(
              icon: Icons.refresh_rounded,
              label: 'إلغاء في أي وقت',
            ),
          ),
          Expanded(
            child: _Badge(
              icon: Icons.account_balance_wallet_rounded,
              label: 'استرداد خلال 7 أيام',
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: QeranColors.gold, size: 22),
        const SizedBox(height: QeranSpacing.s6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: QeranTypography.caption.copyWith(color: QeranColors.wine),
          maxLines: 2,
        ),
      ],
    );
  }
}

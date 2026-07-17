import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class PurchaseFailureScreen extends StatelessWidget {
  /// Localized message KEY for the specific failure cause (card declined,
  /// store unavailable, already-owned, sign-in-required, …) classified by
  /// `purchaseFailureMessage`. Falls back to the generic message when null
  /// (e.g. the free-tier `/subscribe` path, which has no typed RC failure).
  final String? messageKey;
  const PurchaseFailureScreen({super.key, this.messageKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.paper,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card Declined Visuals
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: QeranColors.gold.withValues(alpha: 0.50),
                          width: 1.4,
                        ),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: QeranColors.wine.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.credit_card_off_rounded,
                        size: 36,
                        color: QeranColors.wine,
                      ),
                    ),
                  ],
                ),
              ),
              QeranSpacing.vs24,
              // Title
              Text(
                LocaleKeys.subscriptions_payment_failed_title.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.headline.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: QeranColors.wine,
                ),
              ),
              const SizedBox(height: 10),
              // Message
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  (messageKey ?? LocaleKeys.subscriptions_payment_failed_msg)
                      .t(context),
                  textAlign: TextAlign.center,
                  style: QeranTypography.bodySm.copyWith(
                    color: QeranColors.inkBody,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Retry Button
              SizedBox(
                width: double.infinity,
                child: QeranButton(
                  label: LocaleKeys.subscriptions_payment_failed_retry.t(context),
                  // Pops `true` so the purchase flow re-fires the SAME purchase
                  // (Back pops `false` and just returns to the packages screen).
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
              QeranSpacing.vs12,
              // Back Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  LocaleKeys.subscriptions_payment_failed_back.t(context),
                  style: QeranTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: QeranColors.wine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

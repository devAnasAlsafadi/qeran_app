import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';
import '../../domain/entities/validate_code_response.dart';
import '../../domain/helpers/subscription_format.dart';
import '../blocs/purchase/package_purchase_state.dart';

/// The row rendered below the discount input, chosen from [PackagePurchaseState]:
/// validating spinner, applied-discount summary (gold), the iOS-signature edge
/// (wine), or a validation error (wine). Idle/other → nothing.
class DiscountStatusView extends StatelessWidget {
  final PackagePurchaseState state;
  final SubscriptionPricing pricing;
  final VoidCallback onClear;

  const DiscountStatusView({
    super.key,
    required this.state,
    required this.pricing,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PackagePurchaseValidatingCode() => const _ValidatingRow(),
      PackagePurchaseCodeValidationSuccess(:final response) =>
        (Platform.isIOS && !response.hasIosSignature)
            ? _StatusRow(
                success: false,
                text: LocaleKeys.subscriptions_discount_ios_unavailable
                    .t(context),
                onClear: onClear,
              )
            : _StatusRow(
                success: true,
                text: _summary(context, response),
                onClear: onClear,
              ),
      // `message` is non-null (server text, or errors_generic when null) — `.t`
      // translates our keys and passes server text through unchanged.
      PackagePurchaseCodeValidationFailure(:final message) => _StatusRow(
          success: false,
          text: message.t(context),
          onClear: onClear,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  String _summary(BuildContext context, ValidateCodeResponse response) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    final original = pricing.price;
    final finalPrice = original * (100 - response.discountPercent) / 100;
    return LocaleKeys.subscriptions_discount_applied_summary
        .t(context)
        .replaceFirst('{percent}', '${response.discountPercent}')
        .replaceFirst(
          '{finalPrice}',
          SubscriptionFormat.formatPrice(finalPrice, currency),
        )
        .replaceFirst(
          '{originalPrice}',
          SubscriptionFormat.formatPrice(original, currency),
        );
  }
}

class _ValidatingRow extends StatelessWidget {
  const _ValidatingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: QeranSpacing.s12),
      child: Row(
        children: [
          QeranLoader.inline(color: QeranColors.wine),
          QeranSpacing.hs8,
          Text(
            LocaleKeys.subscriptions_validating_code.t(context),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Tinted status pill — gold (success) or wine (error / iOS edge) per the
/// design rules; wine text + a trailing clear (X).
class _StatusRow extends StatelessWidget {
  final bool success;
  final String text;
  final VoidCallback onClear;

  const _StatusRow({
    required this.success,
    required this.text,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final accent = success ? QeranColors.gold : QeranColors.wine;
    return Container(
      margin: const EdgeInsets.only(top: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: success ? 0.15 : 0.10),
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: accent),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 18,
            color: QeranColors.wine,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              text,
              style: QeranTypography.bodySm.copyWith(color: QeranColors.wine),
            ),
          ),
          QeranSpacing.hs8,
          Semantics(
            button: true,
            label: LocaleKeys.subscriptions_clear_code.t(context),
            child: InkWell(
              onTap: onClear,
              borderRadius: QeranRadii.pill,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 18, color: QeranColors.wine),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

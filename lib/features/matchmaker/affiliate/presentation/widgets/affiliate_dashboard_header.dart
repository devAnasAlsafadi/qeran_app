import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/affiliate_commission_type.dart';
import '../../domain/entities/affiliate_summary.dart';
import 'affiliate_count_tile.dart';
import 'affiliate_metric_tile.dart';
import 'affiliate_rate_format.dart';

/// Non-scrolling header of the affiliate dashboard: the shared code, the
/// commission-rate highlight card, the three earnings tiles (Total / Pending /
/// Paid), the two referral-count tiles (Signed up / Converted), and the ledger
/// section title. Sits above the paginated commission list. Currency is
/// backend-driven ([AffiliateSummary.currency]).
class AffiliateDashboardHeader extends StatelessWidget {
  const AffiliateDashboardHeader({super.key, required this.summary});

  final AffiliateSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = summary.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SharedCode(code: summary.referralCode),
        QeranSpacing.vs16,
        _RateCard(
          rate: summary.commissionRate,
          type: summary.commissionType,
          currency: currency,
        ),
        QeranSpacing.vs16,
        Row(
          children: [
            Expanded(
              child: AffiliateMetricTile(
                labelKey: LocaleKeys.matchmaker_affiliate_total_label,
                amount: summary.totalCommission,
                currency: currency,
              ),
            ),
            QeranSpacing.hs8,
            Expanded(
              child: AffiliateMetricTile(
                labelKey: LocaleKeys.matchmaker_affiliate_pending_label,
                amount: summary.pendingCommission,
                currency: currency,
              ),
            ),
            QeranSpacing.hs8,
            Expanded(
              child: AffiliateMetricTile(
                labelKey: LocaleKeys.matchmaker_affiliate_paid_label,
                amount: summary.paidCommission,
                currency: currency,
              ),
            ),
          ],
        ),
        QeranSpacing.vs8,
        Row(
          children: [
            Expanded(
              child: AffiliateCountTile(
                labelKey: LocaleKeys.matchmaker_affiliate_signed_up_label,
                count: summary.registeredUsersCount,
              ),
            ),
            QeranSpacing.hs8,
            Expanded(
              child: AffiliateCountTile(
                labelKey: LocaleKeys.matchmaker_affiliate_converted_label,
                count: summary.codeUsedCount,
              ),
            ),
          ],
        ),
        QeranSpacing.vs24,
        Text(
          LocaleKeys.matchmaker_affiliate_ledger_title.t(context),
          style: QeranTypography.title.copyWith(color: QeranColors.inkStrong),
        ),
        QeranSpacing.vs8,
      ],
    );
  }
}

/// Dedicated gold-tinted highlight card for the matchmaker's commission rate —
/// the headline number of the dashboard. The value is backend-driven and
/// forward-safe: `10%` for a percent rate, `10 USD` for a (reserved) fixed
/// rate, and a neutral `—` when no rate has been set (never fabricated).
class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.rate,
    required this.type,
    required this.currency,
  });

  final double? rate;
  final AffiliateCommissionType? type;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final value = formatCommissionRate(rate, type, currency) ??
        LocaleKeys.matchmaker_affiliate_rate_none.t(context);
    final hasRate = rate != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s16,
      ),
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.matchmaker_affiliate_rate_label.t(context),
            style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
          ),
          QeranSpacing.vs8,
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: QeranTypography.headline.copyWith(
              color: hasRate ? QeranColors.goldDeep : QeranColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The matchmaker's own shared code on a gold-tinted pill (read-only here — the
/// copy/share affordance lives on the account referral card).
class _SharedCode extends StatelessWidget {
  const _SharedCode({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              LocaleKeys.matchmaker_affiliate_shared_code_label.t(context),
              style:
                  QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
            ),
          ),
          QeranSpacing.hs12,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s12,
              vertical: QeranSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: QeranColors.gold12,
              borderRadius: QeranRadii.controlR,
              border: Border.all(color: QeranColors.gold40),
            ),
            child: Text(
              code,
              textDirection: TextDirection.ltr,
              style: QeranTypography.numeric.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}

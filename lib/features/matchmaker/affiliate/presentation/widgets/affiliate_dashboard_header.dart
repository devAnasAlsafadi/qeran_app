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
import 'affiliate_codes_section.dart';
import 'affiliate_rate_format.dart';

part 'affiliate_dashboard_header_parts.dart';

/// Non-scrolling header of the affiliate dashboard: the primary code, the
/// commission-rate highlight card, the three earnings tiles (Total / Pending /
/// Paid), the two referral-count tiles (Signed up / Converted), the per-code
/// breakdown, and the ledger section title. Sits above the paginated
/// commission list. Currency is backend-driven ([AffiliateSummary.currency]).
///
/// The tiles are ACCOUNT-level: they sum every code. That is why the breakdown
/// follows them rather than the code at the top — a single code named above a
/// set of totals is read as owning them, which is what it used to do.
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
        AffiliateCodesSection(
          codes: summary.codes,
          accountRate: summary.commissionRate,
          commissionType: summary.commissionType,
          currency: currency,
        ),
        Text(
          LocaleKeys.matchmaker_affiliate_ledger_title.t(context),
          style: QeranTypography.title.copyWith(color: QeranColors.inkStrong),
        ),
        QeranSpacing.vs8,
      ],
    );
  }
}

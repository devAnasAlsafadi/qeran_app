part of 'affiliate_dashboard_header.dart';

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

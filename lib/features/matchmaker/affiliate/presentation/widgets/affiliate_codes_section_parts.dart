part of 'affiliate_codes_section.dart';

/// ⚠️ The two numbers on this row belong to different people.
///
/// [AffiliateCode.totalCommission] is the matchmaker's money and is the only
/// thing here rendered with a currency. [AffiliateCode.discountPercent] is what
/// the BUYER saves — a code can give 50% off while earning her 10%, so showing
/// the 50 as earnings would overstate her income fivefold. It is kept to a
/// muted caption, given its own key, and never placed beside an amount.
class _CodeRow extends StatelessWidget {
  const _CodeRow({
    required this.code,
    required this.accountRate,
    required this.commissionType,
    required this.currency,
  });

  final AffiliateCode code;
  final double? accountRate;
  final AffiliateCommissionType? commissionType;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final rate = formatPerCodeRate(
      code.commissionRate,
      accountRate,
      commissionType,
      currency,
    );
    return QeranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CodePill(code: code.code),
              if (code.isPrimary) ...[
                QeranSpacing.hs8,
                const _PrimaryBadge(),
              ],
              const Spacer(),
              // The matchmaker's money. Keyed on its own so a test can assert
              // it holds the commission and not the buyer's discount.
              Text(
                key: ValueKey<String>('affiliate-code-earned-${code.code}'),
                '${_money(code.totalCommission)} $currency',
                textDirection: TextDirection.ltr,
                style: QeranTypography.subtitle.copyWith(
                  color: QeranColors.goldDeep,
                ),
              ),
            ],
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.matchmaker_affiliate_code_used_count.t(
              context,
              namedArgs: {'count': '${code.codeUsedCount}'},
            ),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
          ),
          QeranSpacing.vs4,
          // Somebody else's saving, deliberately quiet: no gold, no currency,
          // and a separate widget from the amount above.
          Text(
            key: ValueKey<String>('affiliate-code-discount-${code.code}'),
            LocaleKeys.matchmaker_affiliate_code_buyer_discount.t(
              context,
              namedArgs: {'percent': _percent(code.discountPercent)},
            ),
            style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
          ),
          if (rate != null) ...[
            QeranSpacing.vs4,
            Text(
              LocaleKeys.matchmaker_affiliate_rate_label.t(context),
              style:
                  QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
            ),
            Text(
              rate,
              textDirection: TextDirection.ltr,
              style: QeranTypography.bodySm
                  .copyWith(color: QeranColors.inkStrong),
            ),
          ],
        ],
      ),
    );
  }

  /// Matches the earnings tiles above: whole amounts drop the decimals.
  static String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  static String _percent(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s4,
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
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.matchmaker_affiliate_code_primary_badge.t(context),
      style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
    );
  }
}

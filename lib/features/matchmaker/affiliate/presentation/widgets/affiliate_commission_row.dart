import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../domain/entities/affiliate_commission.dart';
import '../../domain/entities/affiliate_commission_status.dart';
import 'affiliate_status_chip.dart';

/// One commission-ledger row: who (masked user + plan) and the coupon/date on
/// the leading side; the amount + settlement chip trailing. A reversed amount
/// is struck through in ink-muted with no sign; confirmed / pending amounts are
/// prefixed `+` in gold-deep. Currency is the backend `currency` field passed in
/// (today always `USD`) — never a hardcoded literal.
class AffiliateCommissionRow extends StatelessWidget {
  const AffiliateCommissionRow({
    super.key,
    required this.commission,
    required this.currency,
  });

  final AffiliateCommission commission;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Leading(commission: commission)),
          QeranSpacing.hs12,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Amount(commission: commission, currency: currency),
              QeranSpacing.vs8,
              AffiliateStatusChip(status: commission.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.commission});

  final AffiliateCommission commission;

  @override
  Widget build(BuildContext context) {
    final date = commission.date;
    final dateText =
        date == null ? null : DateFormat.yMMMd(context.locale.toString()).format(date);
    final meta = [
      if (commission.discountCode.isNotEmpty) commission.discountCode,
      ?dateText,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          commission.userDisplay,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: QeranTypography.body.copyWith(
            color: QeranColors.inkStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (commission.planName.isNotEmpty) ...[
          QeranSpacing.vs4,
          Text(
            commission.planName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
          ),
        ],
        if (meta.isNotEmpty) ...[
          QeranSpacing.vs4,
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                QeranTypography.caption.copyWith(color: QeranColors.inkFaint),
          ),
        ],
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.commission, required this.currency});

  final AffiliateCommission commission;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final reversed =
        commission.status == AffiliateCommissionStatus.reversed;
    final prefix = reversed ? '' : '+';
    final amount = '$prefix${_money(commission.amount)} $currency';
    return Text(
      amount,
      textDirection: TextDirection.ltr,
      style: QeranTypography.numeric.copyWith(
        color: reversed ? QeranColors.inkMuted : QeranColors.goldDeep,
        decoration: reversed ? TextDecoration.lineThrough : null,
        decorationColor: reversed ? QeranColors.inkMuted : null,
      ),
    );
  }

  static String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';

/// One earnings tile (Total / Pending / Paid). The money value uses
/// [QeranTypography.numeric] (Montserrat tabular figures) and is LTR-pinned so
/// the amount + currency read left-to-right in both locales. Currency is the
/// backend `currency` field passed in (today always `USD`) — never a hardcoded
/// literal.
class AffiliateMetricTile extends StatelessWidget {
  const AffiliateMetricTile({
    super.key,
    required this.labelKey,
    required this.amount,
    required this.currency,
  });

  /// Locale key for the tile caption (run through `.t`).
  final String labelKey;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return QeranCard.flat(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelKey.t(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
          ),
          QeranSpacing.vs8,
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    _money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QeranTypography.numeric
                        .copyWith(color: QeranColors.inkStrong),
                  ),
                ),
                QeranSpacing.hs4,
                Text(
                  currency,
                  style: QeranTypography.caption
                      .copyWith(color: QeranColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Whole amounts show no decimals; fractional amounts show two.
  static String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

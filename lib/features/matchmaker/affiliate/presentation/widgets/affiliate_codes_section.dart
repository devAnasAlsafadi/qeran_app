import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/affiliate_code.dart';
import '../../domain/entities/affiliate_commission_type.dart';
import 'affiliate_rate_format.dart';

part 'affiliate_codes_section_parts.dart';

/// One row per code the matchmaker holds, each with its OWN redemptions and
/// earnings.
///
/// The account totals above this section are the SUM across these rows. Before
/// the backend sent a list, the dashboard named one code and showed those sums
/// beneath it, so a second code's earnings read as the first one's.
///
/// Renders NOTHING for an empty list — no title, no divider, no empty state.
/// An account with one code (or a payload from before the list existed) should
/// look exactly as it did.
class AffiliateCodesSection extends StatelessWidget {
  const AffiliateCodesSection({
    super.key,
    required this.codes,
    required this.accountRate,
    required this.commissionType,
    required this.currency,
  });

  final List<AffiliateCode> codes;

  /// The matchmaker's headline rate, used only to decide whether a row's own
  /// rate is worth showing — see [formatPerCodeRate].
  final double? accountRate;

  final AffiliateCommissionType? commissionType;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (codes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.matchmaker_affiliate_codes_title.t(context),
          style: QeranTypography.title.copyWith(color: QeranColors.inkStrong),
        ),
        QeranSpacing.vs8,
        for (final code in codes) ...[
          _CodeRow(
            code: code,
            accountRate: accountRate,
            commissionType: commissionType,
            currency: currency,
          ),
          QeranSpacing.vs8,
        ],
        QeranSpacing.vs16,
      ],
    );
  }
}

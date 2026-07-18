import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';

/// One referral-count tile (Signed up / Converted). Sibling of
/// [AffiliateMetricTile] — same flat-card visual, but renders a whole-number
/// [count] with no currency suffix. The number uses [QeranTypography.numeric]
/// (tabular figures) and is LTR-pinned so it reads left-to-right in both
/// locales.
class AffiliateCountTile extends StatelessWidget {
  const AffiliateCountTile({
    super.key,
    required this.labelKey,
    required this.count,
  });

  /// Locale key for the tile caption (run through `.t`).
  final String labelKey;
  final int count;

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
          Text(
            '$count',
            textDirection: TextDirection.ltr,
            style:
                QeranTypography.numeric.copyWith(color: QeranColors.inkStrong),
          ),
        ],
      ),
    );
  }
}

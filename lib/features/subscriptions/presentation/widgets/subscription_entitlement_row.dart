import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// One entitlement line on the My-subscription card — the "remaining this cycle"
/// centerpiece. Three shapes, chosen by the caller from real `/current` data:
///  * **unlimited** → a gold "غير محدود" pill, no bar (feature name always kept).
///  * **counter** → "{remaining} of {total} left" + a gold progress bar showing
///    how much of the cycle is still available ([barFraction] = remaining/total).
///  * **allowance** → a plain value with no bar (daily-views has no remaining
///    counter in `/current`, so we show the allowance rather than fake a total).
class SubscriptionEntitlementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueText;

  /// Gold "unlimited" pill styling when true; plain value text otherwise.
  final bool unlimited;

  /// remaining/total in `[0, 1]`; null renders no bar (unlimited / allowance).
  final double? barFraction;

  const SubscriptionEntitlementRow({
    super.key,
    required this.icon,
    required this.label,
    required this.valueText,
    this.unlimited = false,
    this.barFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: QeranColors.wine),
              QeranSpacing.hs12,
              Expanded(
                child: Text(
                  label,
                  style: QeranTypography.bodySm.copyWith(
                    color: QeranColors.inkBody,
                  ),
                ),
              ),
              if (unlimited)
                _UnlimitedPill(text: valueText)
              else
                Text(
                  valueText,
                  style: QeranTypography.numeric.copyWith(
                    color: QeranColors.inkStrong,
                  ),
                ),
            ],
          ),
          if (barFraction != null) ...[
            QeranSpacing.vs8,
            ClipRRect(
              borderRadius: QeranRadii.pill,
              child: LinearProgressIndicator(
                value: barFraction!.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: QeranColors.wine08,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  QeranColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlimitedPill extends StatelessWidget {
  final String text;
  const _UnlimitedPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: QeranColors.gold20,
        borderRadius: QeranRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.all_inclusive_rounded,
            size: 14,
            color: QeranColors.goldDeep,
          ),
          QeranSpacing.hs4,
          Text(
            text,
            style: QeranTypography.label.copyWith(color: QeranColors.goldDeep),
          ),
        ],
      ),
    );
  }
}

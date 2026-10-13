part of 'plan_selection_widget.dart';

/// The plan-card price line. Renders the store price when there is one, a
/// shimmer while the catalogue is still loading, and nothing once the store has
/// answered without one: the plan's content stands without a price, and the
/// screen says once, in the buy button's place, that it can't be bought (run
/// 10).
///
/// It never shows the API's `price` (nor `originalPrice`, `discountPercent`,
/// `monthlyEquivalent`): they carry no currency and aren't what the store
/// charges.
class _PlanCardPrice extends StatelessWidget {
  const _PlanCardPrice({
    required this.priceText,
    required this.storeResolved,
  });

  /// The whole line, period included ("SAR 99.99 / 3 أشهر").
  final String? priceText;
  final bool storeResolved;

  @override
  Widget build(BuildContext context) {
    final style = QeranTypography.bodySm.copyWith(color: QeranColors.inkBody);
    final text = priceText;

    if (text == null) {
      if (!storeResolved) {
        return const QeranSkeleton.box(width: 96, height: 16);
      }
      return const SizedBox.shrink();
    }

    return Text(text, style: style);
  }
}

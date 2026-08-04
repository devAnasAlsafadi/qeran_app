part of 'plan_selection_widget.dart';

/// The plan-card price line. Renders the store price when there is one, a
/// shimmer while the catalogue is still loading, and a plain "unavailable" note
/// once the store has answered without a price for this product.
///
/// It never falls back to the backend `price`: that figure is administrative
/// and differs from the amount the store charges, so showing it would state a
/// price the user is not going to pay.
class _PlanCardPrice extends StatelessWidget {
  const _PlanCardPrice({
    required this.priceText,
    required this.isFreePlan,
    required this.storeResolved,
  });

  final String? priceText;
  final bool isFreePlan;
  final bool storeResolved;

  @override
  Widget build(BuildContext context) {
    final style = QeranTypography.bodySm.copyWith(color: QeranColors.inkBody);
    final text = priceText;

    if (text == null) {
      if (!storeResolved) {
        return const QeranSkeleton.box(width: 96, height: 16);
      }
      return Text(
        LocaleKeys.subscriptions_purchase_package_not_found.t(context),
        style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
      );
    }

    // Free reads just "مجاني" — no "/شهريًا" suffix.
    if (isFreePlan) return Text(text, style: style);
    return Text(
      '$text ${LocaleKeys.subscriptions_per_month.t(context)}',
      style: style,
    );
  }
}

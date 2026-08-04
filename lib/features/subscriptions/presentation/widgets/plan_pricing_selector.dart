import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import 'pricing_row_widget.dart';

/// The billing-period picker shown inside an expanded plan card when the plan
/// exposes more than one pricing (e.g. VIP: monthly + 3-month). Each row is a
/// reused [PricingRowWidget]; tapping one drives [onPricingSelected], which the
/// screen routes to the cubit's `selectPricing` — the single source the card
/// price, order summary, and charge all read back through.
///
/// Rendered only by the plan card, but lives in its own file to keep
/// `plan_selection_widget.dart` within the file-size budget.
class PlanPricingSelector extends StatelessWidget {
  final SubscriptionPlan plan;
  final int? selectedPricingId;
  final StoreProduct? Function(SubscriptionPricing pricing) resolveStoreProduct;

  /// False while the store catalogue is still loading — passed through to each
  /// row so a late price shows a placeholder rather than the backend figure.
  final bool storeResolved;
  final ValueChanged<int> onPricingSelected;

  const PlanPricingSelector({
    super.key,
    required this.plan,
    required this.selectedPricingId,
    required this.resolveStoreProduct,
    required this.storeResolved,
    required this.onPricingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pricings = plan.activePricings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < pricings.length; i++) ...[
          if (i > 0) QeranSpacing.vs8,
          PricingRowWidget(
            pricing: pricings[i],
            storeProduct: resolveStoreProduct(pricings[i]),
            storeResolved: storeResolved,
            selected: pricings[i].id == selectedPricingId,
            onTap: () => onPricingSelected(pricings[i].id),
          ),
        ],
      ],
    );
  }
}

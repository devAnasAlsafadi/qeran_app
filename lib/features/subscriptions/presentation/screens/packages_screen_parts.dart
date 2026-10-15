part of 'packages_screen.dart';

/// The chosen plan's summary and the buy button, then «استعادة المشتريات»
/// and the legal links.
///
/// No store price means no purchase: the amount cannot be disclosed, and
/// RevenueCat would fail to find the package anyway. Once the store has
/// answered without it, the code field and the button give way to one line
/// saying so (runs 10 and 11). The plan and period they hold: the button says
/// «باقتك الحالية» and is off, with no code field (run 11).
class _Checkout extends StatelessWidget {
  const _Checkout({
    required this.plan,
    required this.pricing,
    required this.storeProduct,
    required this.storeResolved,
    required this.owned,
    required this.isIOS,
    required this.freeBusy,
    required this.onBuy,
  });

  final SubscriptionPlan plan;
  final SubscriptionPricing? pricing;
  final StoreProduct? storeProduct;
  final bool storeResolved;
  final bool owned;
  final bool isIOS;
  final bool freeBusy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final pricing = this.pricing;
    final priceUnavailable = pricing != null && storeProduct == null;
    final unavailable = priceUnavailable && storeResolved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pricing != null) ...[
          QeranSpacing.vs16,
          OrderSummaryWidget(
            planName: plan.name(
              isArabic: Localizations.localeOf(context).languageCode == 'ar',
            ),
            pricing: pricing,
            storeProduct: storeProduct,
            // Android keeps sending the Google id it has always sent; iOS
            // resolves its own, though the field is hidden there anyway.
            codeProductId: isIOS
                ? (pricing.appleProductId ?? pricing.storeProductId)
                : pricing.googleProductId,
            allowDiscountCode: !isIOS && !unavailable && !owned,
          ),
        ],
        QeranSpacing.vs24,
        BlocBuilder<PackagePurchaseCubit, PackagePurchaseState>(
          builder: (context, purchaseState) => StickyCtaWidget(
            unavailable: unavailable,
            owned: owned,
            hasSelection: pricing != null && !priceUnavailable,
            freeBusy: freeBusy,
            discountPercent:
                purchaseState is PackagePurchaseCodeValidationSuccess
                ? purchaseState.response.discountPercent
                : null,
            onPressed: pricing == null || priceUnavailable ? null : onBuy,
          ),
        ),
        QeranSpacing.vs12,
        // Apple requires a visible "Restore purchases" on the purchase
        // surface. Self-contained tile (own cubit + restore-specific outcome
        // handling), enabled on both platforms — restore triggers no payment.
        const RestorePurchasesTile(),
        QeranSpacing.vs12,
        // Apple 3.1.2(a): the subscription binding + both legal documents
        // must be reachable from the surface that sells the subscription.
        const LegalLinksRow(),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return QeranErrorState(
      title: LocaleKeys.subscriptions_load_failed.t(context),
      message: message,
      retryLabel: LocaleKeys.subscriptions_retry.t(context),
      onRetry: () => context.read<SubscriptionPlansCubit>().load(),
    );
  }
}

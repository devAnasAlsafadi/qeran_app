import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';
import '../../domain/helpers/subscription_format.dart';
import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';

part 'order_summary_parts.dart';

/// The "Order summary" card (Android-only paywall). Always renders the plan +
/// the real store subtotal + a coupon field. Once a code validates, it adds the
/// applied-coupon tag, a "% off" badge, the discount percent, and a
/// "final price at checkout" note.
///
/// It NEVER computes a final charge: the discounted price is realized by Google
/// Play at purchase (source of truth). The discount is shown only as a percent
/// (backed by validate-code); the subtotal is the store's own `priceString`.
/// Same cubit calls, reject-message path, and clear/reset as the prior widget.
class OrderSummaryWidget extends StatefulWidget {
  const OrderSummaryWidget({
    super.key,
    required this.planName,
    required this.pricing,
    required this.storeProduct,
  });

  final String planName;
  final SubscriptionPricing pricing;
  final StoreProduct? storeProduct;

  @override
  State<OrderSummaryWidget> createState() => _OrderSummaryWidgetState();
}

class _OrderSummaryWidgetState extends State<OrderSummaryWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final code = _controller.text.trim().toUpperCase();
    final productId = widget.pricing.googleProductId;
    if (code.isEmpty || productId == null) return;
    context
        .read<PackagePurchaseCubit>()
        .validateDiscountCode(code: code, productId: productId);
  }

  void _remove() {
    _controller.clear();
    context.read<PackagePurchaseCubit>().reset();
  }

  /// Subtotal = the real store price; backend price is the fallback only when
  /// the store product hasn't resolved. No discount math either way.
  String _subtotal(BuildContext context) {
    final store = widget.storeProduct;
    if (store != null) return store.priceString;
    final currency = LocaleKeys.subscriptions_currency.t(context);
    return SubscriptionFormat.formatPrice(widget.pricing.price, currency);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagePurchaseCubit, PackagePurchaseState>(
      builder: (context, state) {
        final applied = state is PackagePurchaseCodeValidationSuccess &&
                state.response.valid
            ? state.response
            : null;
        final validating = state is PackagePurchaseValidatingCode;
        final locked = validating || state is PackagePurchaseInProgress;
        final rejectMessage =
            state is PackagePurchaseCodeValidationFailure ? state.message : null;

        return QeranCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.subscriptions_order_summary_title.t(context),
                style: QeranTypography.subtitle
                    .copyWith(color: QeranColors.inkStrong),
              ),
              QeranSpacing.vs12,
              _PlanRow(name: widget.planName),
              QeranSpacing.vs12,
              _SummaryRow(
                label: LocaleKeys.subscriptions_order_summary_subtotal
                    .t(context),
                value: _subtotal(context),
                valueLtr: true,
              ),
              QeranSpacing.vs12,
              if (applied == null)
                _CouponField(
                  controller: _controller,
                  locked: locked,
                  onValidate: _validate,
                )
              else
                _AppliedCouponRow(
                  offerId: applied.offerId ?? '',
                  percent: applied.discountPercent,
                  onRemove: _remove,
                ),
              if (validating) ...[QeranSpacing.vs12, const _ValidatingRow()],
              if (rejectMessage != null) ...[
                QeranSpacing.vs12,
                _RejectRow(message: rejectMessage.t(context)),
              ],
              if (applied != null) ...[
                QeranSpacing.vs12,
                _SummaryRow(
                  label: LocaleKeys.subscriptions_order_summary_discount
                      .t(context),
                  value: '−${applied.discountPercent}%',
                  valueLtr: true,
                  valueColor: QeranColors.goldDeep,
                ),
                const _RowDivider(),
                _SummaryRow(
                  label:
                      LocaleKeys.subscriptions_order_summary_total.t(context),
                  value: LocaleKeys.subscriptions_order_summary_total_note
                      .t(context),
                  valueColor: QeranColors.inkStrong,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Selected-plan name line at the top of the summary card.
class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: QeranTypography.body.copyWith(color: QeranColors.wine),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Hairline between the discount and total rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: QeranColors.divider),
      ),
    );
  }
}

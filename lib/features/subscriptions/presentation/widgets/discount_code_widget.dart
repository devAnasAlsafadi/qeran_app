import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';
import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';
import 'discount_status_view.dart';

/// Discount-code input for the paywall (Android only — the coordinator hides it
/// on iOS per Q-B). The trimmed, upper-cased code is validated on Apply; the
/// outcome renders below via [DiscountStatusView].
class DiscountCodeWidget extends StatefulWidget {
  final SubscriptionPricing pricing;
  const DiscountCodeWidget({super.key, required this.pricing});

  @override
  State<DiscountCodeWidget> createState() => _DiscountCodeWidgetState();
}

class _DiscountCodeWidgetState extends State<DiscountCodeWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim().toUpperCase();
    final productId = widget.pricing.googleProductId;
    if (code.isEmpty || productId == null) return;
    context
        .read<PackagePurchaseCubit>()
        .validateDiscountCode(code: code, productId: productId);
  }

  void _clear() {
    _controller.clear();
    context.read<PackagePurchaseCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagePurchaseCubit, PackagePurchaseState>(
      builder: (context, state) {
        final locked = state is PackagePurchaseValidatingCode ||
            state is PackagePurchaseInProgress;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: QeranTextField(
                    controller: _controller,
                    hint: LocaleKeys.subscriptions_discount_code_placeholder
                        .t(context),
                    enabled: !locked,
                    maxLength: 20,
                    textInputAction: TextInputAction.done,
                    onSubmitted: locked ? null : (_) => _apply(),
                  ),
                ),
                QeranSpacing.hs12,
                QeranButton(
                  label: LocaleKeys.subscriptions_apply_code.t(context),
                  variant: QeranButtonVariant.primary,
                  size: QeranButtonSize.sm,
                  fullWidth: false,
                  onPressed: locked ? null : _apply,
                ),
              ],
            ),
            DiscountStatusView(
              state: state,
              pricing: widget.pricing,
              onClear: _clear,
            ),
          ],
        );
      },
    );
  }
}

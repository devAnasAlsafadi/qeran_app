import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/purchase/subscription_purchase_cubit.dart';
import '../blocs/purchase/subscription_purchase_state.dart';

/// Compact discount-code surface for the purchase screen. Collapsed
/// behind a "Have a discount code?" toggle so it doesn't compete with
/// the price summary. Validates on the "Apply" button only — never on
/// keystroke — and renders the four cubit states (idle / validating /
/// applied / invalid) inline.
class DiscountCodeField extends StatefulWidget {
  const DiscountCodeField({super.key});

  @override
  State<DiscountCodeField> createState() => _DiscountCodeFieldState();
}

class _DiscountCodeFieldState extends State<DiscountCodeField> {
  late final TextEditingController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SubscriptionPurchaseCubit>().state.discountInput,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionPurchaseCubit, SubscriptionPurchaseState>(
      listenWhen: (prev, curr) =>
          prev.discountInput != curr.discountInput &&
          curr.discountInput != _controller.text,
      listener: (_, state) {
        _controller.value = TextEditingValue(
          text: state.discountInput,
          selection: TextSelection.collapsed(offset: state.discountInput.length),
        );
      },
      builder: (context, state) {
        final hasApplied = state.discount?.isValid == true;
        final validating = state is SubscriptionPurchaseValidatingDiscount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
                child: Row(
                  children: [
                    Icon(
                      hasApplied
                          ? Icons.local_offer_rounded
                          : Icons.local_offer_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppDimens.p8),
                    Expanded(
                      child: Text(
                        hasApplied
                            ? LocaleKeys.subscriptions_discount_applied
                                .t(context)
                            : LocaleKeys.subscriptions_have_discount.t(context),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _Field(
                controller: _controller,
                validating: validating,
                state: state,
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final bool validating;
  final SubscriptionPurchaseState state;

  const _Field({
    required this.controller,
    required this.validating,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionPurchaseCubit>();
    final hasApplied = state.discount?.isValid == true;
    final invalid = state is SubscriptionPurchaseDiscountInvalid;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !hasApplied && !validating,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    LengthLimitingTextInputFormatter(24),
                  ],
                  onChanged: cubit.onDiscountInputChanged,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.subscriptions_discount_placeholder
                        .t(context),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p16,
                      vertical: AppDimens.p12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              SizedBox(
                height: 48,
                child: hasApplied
                    ? _RemoveButton(onPressed: cubit.removeDiscount)
                    : _ApplyButton(
                        onPressed:
                            validating ? null : () => cubit.applyDiscount(),
                        loading: validating,
                      ),
              ),
            ],
          ),
          if (invalid)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.p8),
              child: Text(
                LocaleKeys.subscriptions_discount_invalid.t(context),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  const _ApplyButton({required this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    // The app-wide ElevatedButtonThemeData defaults `minimumSize` to
    // `Size(double.infinity, 55)` for full-width primary CTAs. That
    // makes any inline ElevatedButton inside a Row request infinite
    // width — which throws "BoxConstraints forces an infinite width"
    // at layout time. Override `minimumSize` here so the button sizes
    // to its content (with a 48 dp tap-friendly minimum height).
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(
              LocaleKeys.subscriptions_discount_apply.t(context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // TextButton uses Material defaults (not the app's elevated-button
    // theme), so it doesn't trip the infinite-width assertion. We
    // still pin `minimumSize` so the layout stays predictable if the
    // global theme is ever extended to TextButtons.
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      ),
      child: Text(
        LocaleKeys.subscriptions_discount_remove.t(context),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

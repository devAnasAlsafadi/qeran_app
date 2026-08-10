part of 'order_summary_widget.dart';

/// A label/value line. Numeric values ([valueLtr]) are pinned LTR so a Latin
/// store price ("SAR 50.00") or a "−20%" never RTL-reorders.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueLtr = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueLtr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
          ),
        ),
        QeranSpacing.hs12,
        Text(
          value,
          textDirection: valueLtr ? TextDirection.ltr : null,
          style: QeranTypography.subtitle.copyWith(
            color: valueColor ?? QeranColors.inkStrong,
          ),
        ),
      ],
    );
  }
}

/// Coupon input + Validate button (shown before a valid code is applied).
class _CouponField extends StatelessWidget {
  const _CouponField({
    required this.controller,
    required this.locked,
    required this.onValidate,
  });

  final TextEditingController controller;
  final bool locked;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: QeranTextField(
            controller: controller,
            hint: LocaleKeys.subscriptions_discount_code_placeholder.t(context),
            enabled: !locked,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            onSubmitted: locked ? null : (_) => onValidate(),
          ),
        ),
        QeranSpacing.hs12,
        QeranButton(
          label: LocaleKeys.subscriptions_validate_code.t(context),
          variant: QeranButtonVariant.primary,
          size: QeranButtonSize.sm,
          fullWidth: false,
          onPressed: locked ? null : onValidate,
        ),
      ],
    );
  }
}

/// Applied-coupon tag + "% off" badge + Remove (shown after a valid code).
class _AppliedCouponRow extends StatelessWidget {
  const _AppliedCouponRow({
    required this.offerId,
    required this.percent,
    required this.onRemove,
  });

  final String offerId;
  final int percent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (offerId.isNotEmpty)
                QeranChip(
                  label: offerId,
                  variant: QeranChipVariant.interest,
                  icon: Icons.sell_outlined,
                  compact: true,
                ),
              QeranChip(
                label: LocaleKeys.subscriptions_discount_badge
                    .t(context)
                    .replaceFirst('{percent}', '$percent'),
                variant: QeranChipVariant.interest,
                compact: true,
              ),
            ],
          ),
        ),
        QeranSpacing.hs8,
        QeranButton(
          label: LocaleKeys.subscriptions_remove_code.t(context),
          variant: QeranButtonVariant.ghost,
          size: QeranButtonSize.sm,
          fullWidth: false,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

/// Inline spinner while a code is being validated.
class _ValidatingRow extends StatelessWidget {
  const _ValidatingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        QeranLoader.inline(color: QeranColors.wine),
        QeranSpacing.hs8,
        Text(
          LocaleKeys.subscriptions_validating_code.t(context),
          style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
        ),
      ],
    );
  }
}

/// Verbatim server reject message (never hardcoded client-side).
class _RejectRow extends StatelessWidget {
  const _RejectRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 18, color: QeranColors.wine),
        QeranSpacing.hs8,
        Expanded(
          child: Text(
            message,
            style: QeranTypography.bodySm.copyWith(color: QeranColors.wine),
          ),
        ),
      ],
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

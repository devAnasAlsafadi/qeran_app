import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';

/// Bottom CTA. Label + enabled state are derived from the current selection,
/// an optional applied-discount [discountPercent], and the
/// [PackagePurchaseCubit]'s transient states.
///
/// * **Purchasing / validating** (or [freeBusy]) — inline spinner, disabled.
/// * **Applied discount** — "Subscribe now — {percent}% off".
/// * **Default** — "Subscribe now".
/// * **[unavailable]** — no button: the store has no product for the chosen
///   period, so one line in body text says the plan can't be bought now
///   (runs 10 and 11).
/// * **[owned]** — the plan and period they hold: «باقتك الحالية», disabled
///   (run 11).
class StickyCtaWidget extends StatelessWidget {
  final bool hasSelection;
  final bool unavailable;
  final bool owned;
  final bool freeBusy;
  final int? discountPercent;
  final VoidCallback? onPressed;

  const StickyCtaWidget({
    super.key,
    required this.hasSelection,
    required this.onPressed,
    this.freeBusy = false,
    this.discountPercent,
    this.unavailable = false,
    this.owned = false,
  });

  @override
  Widget build(BuildContext context) {
    if (unavailable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
        child: Text(
          LocaleKeys.subscriptions_purchase_package_not_found.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.body,
        ),
      );
    }
    if (owned) {
      return QeranButton(
        label: LocaleKeys.subscriptions_badge_your_plan.t(context),
        variant: QeranButtonVariant.primary,
        onPressed: null,
      );
    }
    return BlocBuilder<PackagePurchaseCubit, PackagePurchaseState>(
      builder: (context, state) {
        final busy = freeBusy ||
            state is PackagePurchaseInProgress ||
            state is PackagePurchaseValidatingCode;
        return QeranButton(
          label: _label(context),
          variant: QeranButtonVariant.primary,
          loading: busy,
          onPressed: hasSelection ? onPressed : null,
        );
      },
    );
  }

  String _label(BuildContext context) {
    final percent = discountPercent;
    if (percent != null && percent > 0) {
      return LocaleKeys.subscriptions_subscribe_now_with_discount
          .t(context)
          .replaceFirst('{percent}', '$percent');
    }
    return LocaleKeys.subscriptions_subscribe_now.t(context);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
class StickyCtaWidget extends StatelessWidget {
  final bool hasSelection;
  final bool freeBusy;
  final int? discountPercent;
  final VoidCallback? onPressed;

  const StickyCtaWidget({
    super.key,
    required this.hasSelection,
    required this.onPressed,
    this.freeBusy = false,
    this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
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

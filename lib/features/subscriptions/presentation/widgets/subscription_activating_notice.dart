import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// "Activating your subscription" (C5): what the app says in place of Free
/// while a purchase the store confirmed waits for the server. Once it has
/// waited ten minutes ([overdue]), a line points to Help & support.
///
/// [inSheet] sets it centred, in the paywall sheet's type; otherwise it reads
/// as a card's text.
class SubscriptionActivatingNotice extends StatelessWidget {
  const SubscriptionActivatingNotice({
    super.key,
    required this.overdue,
    this.inSheet = false,
  });

  final bool overdue;
  final bool inSheet;

  @override
  Widget build(BuildContext context) {
    final align = inSheet ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.subscriptions_activating_title.t(context),
          textAlign: align,
          style: inSheet
              ? QeranTypography.headline
              : QeranTypography.subtitle.copyWith(color: QeranColors.wine),
        ),
        inSheet ? QeranSpacing.vs8 : QeranSpacing.vs4,
        Text(
          LocaleKeys.subscriptions_activating_body.t(context),
          textAlign: align,
          style: inSheet ? QeranTypography.body : QeranTypography.bodySm,
        ),
        if (overdue) ...[QeranSpacing.vs12, _overdueLine(context, align)],
      ],
    );
  }

  /// Ten minutes on: where to turn if it doesn't arrive.
  Widget _overdueLine(BuildContext context, TextAlign align) => Text(
    LocaleKeys.subscriptions_activating_overdue.t(context),
    textAlign: align,
    style: QeranTypography.bodySm.copyWith(
      color: QeranColors.wine,
      fontWeight: FontWeight.w700,
    ),
  );
}
